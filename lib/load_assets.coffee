_    = require 'underscore'
fs   = require 'fs'
path = require 'path'
watch= require 'watch'

module.exports = (_fs=fs,_watch=watch) ->

  Loader =

    buildRegex: (extensions) ->
      extensions ||= []
      return new RegExp('\\.' + extensions.join('$|\\.') + '$') 

    walkDir: (dir,filter,cb) ->
      func = arguments.callee
      files = _fs.readdirSync(dir)
          
      wrapped = (file,dir) ->

        if cb.length == 1 && file  then cb(file)
        else cb(file,dir)

      _.each files, (f) ->
          
        filePath = path.join(dir,f)
        stats = _fs.lstatSync(filePath)
        cond = true

        if filter && _.isFunction(filter) then cond = filter(f)
        if filter && _.isRegExp(filter) then cond = filter.test(f)
        if cond && stats.isFile() then wrapped(filePath,null)

        if stats.isDirectory()
          wrapped(null,filePath)
          func(filePath,filter,cb)

    addDir: (dir,handler,filter) ->
      if _.isArray(filter) then filter = (@buildRegex filter)

      @walkDir dir, filter, (f) ->

        console.log "Add File: #{f}"
        handler.addFile(f)

    loadAssets: (assets,handler,assetDir,extensions) ->

      unless assets then return
      assets = [assets] unless (_.isArray assets)

      fileRegex = @buildRegex(extensions)

      _.each assets, (asset) =>
        if(f = asset.require) 
          filePath = path.join(assetDir,f)
          handler.addFile(filePath)
          
          console.log "Add File: #{filePath}"

        if(dir = asset.require_tree) 
          requirePath = path.join(assetDir,dir)
          @addDir(requirePath,handler,fileRegex)

    loadTemplates: (assetRoot,templates,handler,execJS) ->

      console.log 'Compile templates'
      console.log assetRoot
      engine = templates.engine
      lib = templates.lib
      templateDir = path.join(assetRoot,templates.dir || 'templates')
      console.log templateDir 

      @loadAssets( lib
                , handler
                , assetRoot + '/javascripts'
                )

      if engine == 'handlebars'

        hbsPrecompiler = require 'handlebars-precompiler'
        hbsRegex = @buildRegex(['hbs','handlebars']) 
        
        compile = (file) ->
         return hbsPrecompiler.do
           templates: [file],
           fileRegex: hbsRegex,
           min: false 

        handler.addRaw(compile(templateDir))

        if templates.watch

          updateTemplate = (file) ->
            try
              source = compile(file)
              execJS(source)
            catch err
              console.warn 'Failed to compile template ' + file
              console.warn err

          _watch.createMonitor templateDir, (monitor) ->
            console.log '[start watching] ' +templateDir
            monitor.on 'changed', (f,curr,prev) ->
              if hbsRegex.test(f)
                console.log "[changed file] #{f}"
                updateTemplate(f)
            monitor.on 'created', (f,curr,prev) ->
              if hbsRegex.test(f) 
                console.log "[created file] #{f}"
                updateTemplate(f)
      else 
        console.warn "Template engine #{engine} not supported!"

     # return bound object    
  _.bindAll Loader
