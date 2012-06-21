_            = require 'underscore'
path         = require 'path'
piler        = require 'piler'
utils        = require './utils'
templateHandler    = require './template_handler'
{loadTemplates} = templateHandler()

jsHandler = piler.createJSManager()
cssHandler = piler.createCSSManager()

module.exports = (_utils=utils) ->

  {walkDir,buildRegex} =  _utils()

  Acid =  

    applyOptions: (options) ->
      
      unless options.config
        throw 'No configuration found!'

      try 
        if _.isString options.config
          options.config = require './config'
      catch err
        throw "Could not load configuration file: #{err}"

      unless options.config.assets
        throw 'No assets specified in config!'

      options.assetRoot ||= options.config.assets && options.config.assets.dir
      options.assetRoot ||= 'public'

      _.map ['config','assetRoot','io'], (key) -> options[key]

    # delegate piler methods
    addFile: (file) ->
      
    # this code is executed on the client
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

    execJS: (data) =>
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

    loadAssets: (assets,handler,assetDir,extensions) ->

      unless assets then return
      assets = [assets] unless (_.isArray assets)

      fileRegex = buildRegex(extensions)

      _.each assets, (asset) =>
        if(f = asset.require) 
          filePath = path.join(assetDir,f)
          handler.addFile(filePath)
          
          console.log "Add File: #{filePath}"

        if(dir = asset.require_tree) 
          requirePath = path.join(assetDir,dir)
          @addDir(requirePath,handler,fileRegex)


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
                  , @assetRoot + '/javascripts'
                  , ['js','coffee']
                  )

      if @config.assets.stylesheets
        @loadAssets( @config.assets.javascripts
                  , jsHandler
                  , @assetRoot + '/stylesheets'
                  , ['css','less']
                  )
