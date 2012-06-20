piler        = require 'piler',
fs           = require 'fs',
path         = require 'path',
watch        = require 'watch',
_            = require 'underscore',
sys  = require 'sys'

{buildRegex,loadAssets,loadTemplates,addDir} = require './load_assets'

jsHandler = piler.createJSManager()
cssHandler = piler.createCSSManager()

class Acid

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

    console.log sys.inspect(options)
    _.map ['config','assetRoot','io'], (key) -> options[key]

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
      loadTemplates @assetRoot,@config.assets.templates,jsHandler,execJS

    if @config.assets.javascripts
      loadAssets( @config.assets.javascripts
                , jsHandler
                , @assetRoot + '/javascripts'
                , ['js','coffee']
                )

    if @config.assets.stylesheets
      loadAssets( @config.assets.javascripts
                , jsHandler
                , @assetRoot + '/stylesheets'
                , ['css','less']
                )

module.exports = new Acid()
