Acid
====

Acid is a rails flavored asset pipeline that makes your assets fly... Based on the excellent
[piler](https://github.com/epeli/piler), it adds some extra spice on top of it, like global definition
files, precompilation of client-side templates, hot code pushes, and more..

It was developed for the use with express, backbone.js and handlebars.


Installation
------------

    npm install acid 

Usage
-----

First create a configuration file to define all your assets:

config.coffee:

```coffee
module.exports = 
  assets:
    dir: 'public'

    javascripts: [

      (require: 'vendor/jquery-1.7.1.min.js')
      (require: 'vendor/underscore.js')
      (require: 'vendor/backbone.js')
      
      (require_tree: 'lib/models')
      (require_tree: 'lib/collections')
      (require_tree: 'lib/views')

      (require: 'lib/app.js')
    ]

    stylesheets: [
      (require: 'style.css') 
    ]

    templates:
      dir: 'templates'
      engine: 'handlebars'
      lib: 'vendor/handlebars.runtime.js'
      watch: true
```

Keys:

* `require`: load single file
* `require_tree`: load directory recursive

Acid assumes that you have your asset directory structured like this, if not specified:

  javascripts/
  stylesheets/
  templates/

### Setup Application

Require acid:

    acid = require 'acid'

Load the configuration file:

    config = require 'config'

Bind it to your app:

    acid.bind app, acid: config

For hot code push and live templating you should
also add io, otherwise it will be loaded by default.

  acid.bind app, acid: config, io: io

### Setup View

In your main view you need to add following line, so piler can inject 
the resources:

index.jade:

    !{renderStyleTags()}
    !{renderScriptTags()}

### Live Templating 

Acid will compile all clientside templates for you. Currently only **Handlebars** is supported, which is
a great clientside template engine based on **mustache.js**.
But the real kick is, that it will also watch your template directory for changes, and push the code directly
to the browser, so it will be instantly viewed. Just bind a Backbone event to the Handlebars.set method:

```javascript
  // set up observer on handlebar templates
  Handlebars.templates = Handlebars.templates || {};
  _.extend(Handlebars, Backbone.Events);

  Handlebars.set = _.bind(function(name,template) {
    _.extend(template,Backbone.Events);
    this.templates[name] = template;
    this.trigger('changed',name);
    this.trigger('changed:'+name);
  },Handlebars);
```
 
No you can listen to changes of templates and rerender your view!

### Supported compilers

handlebars, and everything piler supports (coffee, less, stylus)

### Piler API

Most methods from the Piler API are delegated, though they are independent from
the used piler backend. You can to something like this:

```coffee
   acid.addFile('style.css')
   acid.addFile('script.js')
   acid.addFile('script.coffee')

   acid.addRaw('#box { color: pink;}', 'css')

   acid.addExec ->
    $(document).ready() -> 
      start();
```

The required piler manager is matched by the file extension.
You can also use `acid.liveUpdate()` directly without argument.

For more detailed information, have a look at the [piler](https://github.com/epeli/piler) documention.


## Depenencies

* express
* [piler](https://github.com/epeli/piler)
* [handlebars-precompiler](https://github.com/phreax/node-handlebars-precompiler)
* socket.io 

## Development

Acid is still under heavy development. Contribution is always welcome!


