_     = require 'underscore'
path  = require 'path'
watch = require 'watch'
utils = require './utils'

module.exports = (_watch=watch) ->

  {buildRegex} = utils()

  TemplateHandler =

    COMPILERS:
   
      handlebars:
        extensions: ['hbs','handlebars']
        compile: (file) ->
          @hbsPrecompiler ||= require 'handlebars-precompiler'
          @hbsRegex ||= buildRegex @extensions

          @hbsPrecompiler.do
            templates: [file],
            fileRegex: @hbsRegex,
            min: false 

    updateTemplate: (file,compiler,execJS) ->
      try
        source = compiler.compile(file)
        execJS(source)
      catch err
        console.warn 'Failed to compile template ' + file
        console.warn err

    loadTemplates: (assetRoot,templates,handler,execJS) ->

      console.log 'Compile templates'

      engine = templates.engine
      compiler = @COMPILERS[engine]
      unless compiler
        throw "Template engine #{engine} not supported!" 
        
      if templates.lib
        libPath = path.join(assetRoot,'javascripts',templates.lib)
        console.log 'Add Template Lib: ' + libPath
        handler.addFile libPath
      else
        console.warn 'No templating runtime library given?'

      templateDir = path.join(assetRoot,templates.dir || 'templates')
      handler.addRaw compiler.compile(templateDir)
      
      if templates.watch

        hbsRegex = buildRegex compiler.extensions
        console.log hbsRegex
        
        _watch.createMonitor templateDir, (monitor) =>
          console.log '[start watching] ' +templateDir
          monitor.on 'changed', (f,curr,prev) =>
            if hbsRegex.test(f)
              console.log "[changed file] #{f}"
              @updateTemplate(f,compiler,execJS)
          monitor.on 'created', (f,curr,prev) =>
            if hbsRegex.test(f) 
              console.log "[created file] #{f}"
              @updateTemplate(f,compiler,execJS)

  _.bindAll TemplateHandler
