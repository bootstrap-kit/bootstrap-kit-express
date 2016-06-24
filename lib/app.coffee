express    = require 'express'
request    = require 'request'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
path       = require 'path'
fs         = require 'fs'
morgan     = require 'morgan'
Package    = require './package'

dir = process.cwd()

frontendJsFile = path.resolve(dir, 'frontend.js')
frontendCoffeeFile = path.resolve(dir, 'frontend.coffee')

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

    @app.use morgan 'combined'


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
    output += """bootstrapKitApp = require("#{__dirname}/bootstrap-kit-app.coffee")(baseURL);\n"""

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

    # add deps transformation as suggested in http://stackoverflow.com/questions/17881692/get-coffee-script-dependency-tree-with-browserify

    bundle.deps
      transform: coffeeify

    bundle.add frontendCoffeeFile

    console.log "create bundle"

    bundle.bundle (error, result) ->
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
  loadPackage: (args...) ->
    if typeof args[0] is 'string'
      pkg = new Package mountpoint: args[0], mainModule: args[1], name: args[1].name
    else
      pkg = args[0]

    unless pkg instanceof Package
      pkg = new Package pkg

    pkg.mainModule.bkeApp = this

    if pkg.mainModule.backend
      router = express.Router()
      pkg.mainModule.backend({@app, express, router})
      if pkg.mountpoint
        console.log "app mount #{pkg.mountpoint}"
        @app.use(pkg.mountpoint, router)

        console.log "app", @app

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
