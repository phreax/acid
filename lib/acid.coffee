_            = require 'underscore'
path         = require 'path'
piler        = require 'piler'
utils        = require './utils'
templateHandler    = require './template_handler'
{loadTemplates} = templateHandler()

jsHandler = piler.createJSManager()
cssHandler = piler.createCSSManager()
{walkDir,buildRegex} =  utils()

Acid = class

  constructor: ->

    console.log __dirname
    @EXTENSION =
      javascripts: ['js','coffee']
      stylesheets: ['css','less']

     # delegate piler methods
    _.each ['addOb','addExec'], ((fn) ->
      this[fn] = _.bind jsHandler[fn], jsHandler
    ), this

    _.each ['addFile', 'addRaw','addUrl'], ((fn) ->
      this[fn] = (ns_or_file,file,extension) ->
        unless file
          file = ns_or_file

        extension ||= path.extname(file)[1..]

        if extension in @EXTENSION.javascripts
          jsHandler[fn] ns_or_file,file
        if extension in @EXTENSION.stylesheets
          cssHandler[fn] ns_or_file,file
        else
          console.warn "Filetype does not match '#{file}'"
    ), this
    
    _.bindAll this, ['execJS']

  applyOptions: (options) ->
    
    unless options.config
      console.warn 'No configuration found!'
      options.config = {}

    try 
      if _.isString options.config
        options.config = require options.config
    catch err
      throw "Could not load configuration file: #{err}"

    unless options.config.assets
      console.warn 'No assets specified in config!'

    options.assetRoot ||= options.config.assets && options.config.assets.dir
    options.assetRoot ||= 'public'

    _.map ['config','assetRoot','io'], (key) -> options[key]

  lookupPath: (dir,file) ->
    assetDirs = [path.join(@assetRoot,dir), @assetRoot, '']
    for dir in assetDirs
      p = path.join(dir,file)
      if path.existsSync(p)
        return p
     
    console.warn "File '#{file}' not found in paths!" 

  clientUpdater: ->
    console.log 'Starting asset updater..'  

    acid = io.connect '/acid'

    acid.on 'connect', ->
      console.log 'Updater has connected'
    
    acid.on 'disconnect', ->
      console.log 'Updater has disconnected'

    acid.on 'update:js', (data) ->
      console.log 'Updating javascipts'
      if toString.call(data) == '[object Function]'
        data()
      else if toString.call(data) == '[object String]'
        eval(source)
      else
        console.err 'TypeError: Could not evaluate javascript'

  execJS: (data) ->
    if @socket
      console.log 'Hotpush javascript to client'
      @socket.emit('update:js',data)
    else
      console.log 'socket not yet initialized. call bind first'

  addDir: (dir,handler,filter) ->
    if _.isArray(filter) then filter = (buildRegex filter)

    walkDir dir, filter, (f) ->

      console.log "Add File: #{f}"
      handler.addFile(f)

  addModule: (module) -> 
    obj = require module
    jsHandler.addExec obj;

  loadAssets: (assets,handler,assetDir,extensions) ->

    unless assets then return
    assets = [assets] unless (_.isArray assets)

    fileRegex = buildRegex(extensions)

    _.each assets, (asset) =>
      if(f = asset.require) 
        filePath = @lookupPath(assetDir,f)
        handler.addFile(filePath)
        console.log "Add File: #{filePath}"

      if(dir = asset.require_tree) 
        requirePath = @lookupPath(assetDir,dir)
        @addDir(requirePath,handler,fileRegex)
      
      if(m = asset.require_module) 
        if handler == jsHandler
          @addModule m
        else
          console.warn 'No require_module for stylesheets!'

  liveUpdate: ->
    jsHandler.liveUpdate cssHandler, @io

  renderTags: (type) ->
    unless type?
      javascripts: jsHandler.renderTags()
      stylesheets: cssHandler.renderTags()
    else if type in ['css','stylesheets']
      cssHandler.renderTags()
    else if type in ['js','javascripts']
      jsHandler.renderTags()
  
  bind: (app,options)->

    [@config,@assetRoot,@io] = @applyOptions options
    
    unless @io 
      @io = require 'socket.io'
      @io.listen(app)

    @socket = @io.of('/assets')
    
    jsHandler.bind(app)
    cssHandler.bind(app)

    jsHandler.addUrl('/socket.io/socket.io.js')
    jsHandler.addExec(@clientUpdater)

    if @config.assets.templates
      loadTemplates @assetRoot,@config.assets.templates,jsHandler,@execJS

    if @config.assets.javascripts
      @loadAssets( @config.assets.javascripts
                , jsHandler
                , 'javascripts'
                , ['js','coffee']
                )

    if @config.assets.stylesheets
      @loadAssets( @config.assets.stylesheets
                , cssHandler
                , 'stylesheets'
                , ['css','less']
                )

module.exports = new Acid()
