_    = require 'underscore'
fs   = require 'fs'
path = require 'path'

module.exports = (_fs=fs) ->

  Utils  =

    buildRegex: (extensions) ->
      extensions ||= []
      return new RegExp('\\.' + extensions.join('$|\\.') + '$') 

    walkDir: (dir,filter,cb) ->
      func = arguments.callee
      files = _fs.readdirSync(dir)
          
      wrapped = (file,dir) ->

        if cb.length == 1 && file  then cb(file)
        else if cb.length != 1 then cb(file,dir)

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


