express    = require 'express'
request    = require 'request'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
path       = require 'path'
fs         = require 'fs'
Package    = require './package'

frontendJsFile = path.resolve(__dirname, '..', 'frontend.js')
frontendCoffeeFile = path.resolve(__dirname, '..', 'frontend.coffee')

if fs.existsSync frontendJsFile
  fs.unlinkSync frontendJsFile

if fs.existsSync frontendCoffeeFile
  fs.unlinkSync frontendCoffeeFile

# Public: BootstrapKitExpressFactory
#
class BootstrapKitExpressApp
  # Public: create a BootstrapKitExpress
  constructor: (app, opts={}) ->
    @app ?= express()
    @packages = @app.locals.packages = []
    @app.locals.scriptList = []
    @app.locals.cssList = []
    @app.locals.host = host = opts.host or 'localhost'
    @app.locals.port = port = opts.port or 3001
    @app.locals.baseURL = baseURL = opts.baseURL or "http://#{host}:#{port}"

    if opts.middleware
      for middleware in opts.middleware
        @app.use middleware

    @app.get '/frontend.js', (req, res) =>
      console.log "get frontend.js: #{frontendJsFile}"
      if fs.existsSync frontendJsFile
        res.sendFile frontendJsFile

      else
        @createFrontend (error, result) ->
          throw error if error?
          fs.writeFileSync frontendJsFile, result
          res.sendFile frontendJsFile

        process.on 'exit', ->
          fs.unlinkSync frontendJsFile

  # Private: create frontend code from

  createFrontend: (callback) ->
    output = "baseURL = '#{@app.locals.baseURL}';\n"
    output += """bootstrapKitApp = require("./lib/bootstrap-kit-app.coffee")(baseURL);\n"""

    for pkg in @packages
      script = null

      if pkg.mainModule.frontend
        if typeof pkg.mainModule.frontend is 'string'
          script = pkg.mainModule.frontend
        else
          for id, mod of require.cache
            if mod.exports is pkg.mainModule
              script = mod.filename
              break

      if script?
        console.log "include to frontend: #{script}"
        output += """
          bootstrapKitApp.loadPackage("#{pkg.name}", require("#{script}"));\n
        """

    # load state here
    output += """
      bootstrapKitApp.activatePackages();\n
      """

    fs.writeFileSync(frontendCoffeeFile, output)

    bundle = browserify
      extensions: ['.coffee']

    bundle.transform coffeeify,
      bare: false
      header: true

    bundle.add frontendCoffeeFile

    bundle.bundle (error, result) ->
#      fs.unlinkSync frontendCoffeeFile
      callback error, result

  listen: ->
    @app.listen(@app.locals.port)

  findPackageInfo: (dir) ->
    while true
      if fs.existsSync pkginfo = path.resolve(dir, 'package.json')
        pkginfo = JSON.parse fs.readFileSync pkginfo
        break
      if fs.existsSync pkginfo = path.resolve(dir, 'bower.json')
        pkginfo = JSON.parse fs.readFileSync pkginfo
        break

      dir = path.dirname dir

      # TODO: stop in root

    pkginfo

  # Public: register an express application with a mountpoint
  #
  # - `pkg` {Package} obeect or Object with following keys:
  #   * `name`
  #   * `mountpoint`
  #   * `mainModule`
  #
  # TODO: manage server-side serialization
  loadPackage: (pkg) ->
    unless pkg instanceof Package
      pkg = new Package pkg

    pkg.mainModule.bkeApp = this

    if pkg.mainModule.backend
      pkg.mainModule.backend({@app})

    @packages.push pkg

  # Public: register all applications in a folder
  #
  # - `folder`
  # - `prefix`
  #
  loadPackages: (folder, prefix) ->
    fs = require 'fs'
    regex = new RegExp("#{prefix}(.*)")

    for entry in fs.readdirSync(folder)
      if m = entry.match regex
        backendName = path.resolve(folder, entry, 'backend.js')
        try
          @registerApp new AppSpec {
            name: m[1]
            mountpoint: "/#{m[1]}"
            mainModule: require backendName
          }
        catch e
          console.log "error requiring #{backendName}"

  makeApp: (args...) ->
    new BootstrapKitExpressApp args...

  request: (url, args...) ->
    console.log "request #{@app.locals.baseURL}#{url}"
    request "#{@app.locals.baseURL}#{url}", args...

# Public: BootstrapKitExpress object
module.exports = new BootstrapKitExpressApp()
