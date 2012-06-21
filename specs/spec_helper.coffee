_ = require 'underscore'

getFile = (path,tree) ->
  keys = path
  keys = path.split '/' if _.isString(path)
  keys = _.filter keys, (k) -> k != '.'
  [x,xs] = [(_.head keys), (_.tail keys)]
  return tree unless x
  match = _.find tree, (k) -> 
    name = k
    name = (_.first (_.keys k)) if _.isObject(k)
    name == x

  throw "Path does not exist #{keys.join '/'}" unless match

  if _.isEmpty(xs) 
    return match[x] if _.isObject(match)
    return match

  getFile(xs,match[x])


class Stat
  constructor: (@file) ->
  isFile: -> _.isString(@file)
  isDirectory: -> _.isArray(@file) 

class FakeFS 
  
  constructor: (@tree) ->
  
  lstatSync: (path) -> 
    f = getFile path,@tree
    new Stat(f)
 
  readdirSync: (path) ->
    f = getFile path,@tree
    throw "Not a directory #{path}" unless _.isArray(f)

    _.map f, (k) -> 
      k = (_.first (_.keys k)) if _.isObject(k)
      k

module.exports = {FakeFS}
