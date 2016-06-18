bootstrapKit = require 'bootstrap-kit'

# Public: Client-Side class for managing application
#
# Manage an application on client side.
class BootstrapKitApp
  bootstrapKit: bootstrapKit

  # Public: create a BootstrapKitApp instance
  #
  # - `baseURL` {String} baseURL of the application
  #
  # Usually called from exported factory function.
  constructor: (@baseURL) ->
    @packages = {}
    @emitter = new bootstrapKit.Emitter()

  # Public: register an app
  #
  # - `app` {}
  loadPackage: (name, mainModule) ->
    @packages[name] = mainModule

  # Public: serialize package data
  serialize: ->
    state = {}
    for name, pkg of @packages
      pkgState = null

      if pkg.serialize
        pkgState = pkg.serialize()

      state[name] = pkgState

    state

  # Public: Save state to cookie
  saveState: (state=null) ->
    unless state
      state = @serilize()

    @writeCookie 'state', state

  # Public: Load state from cookie
  loadState: ->
    @readCookie 'state'

  # Public: Clear state
  clearState: ->
    @deleteCookie 'state'

  ###
  Section: Handling Cookies

  See http://stackoverflow.com/questions/11344531/pure-javascript-store-object-in-cookie
  ###

  writeCookie: (name, value) ->
    cookie = [name, '=', encodeURIComponent(JSON.stringify(value)),
      '; domain=.', window.location.host.toString(), '; path=/;'].join('');
    document.cookie = cookie;

  # Public: get cookie by name
  #
  # Algorithm from http://stackoverflow.com/questions/10730362/get-cookie-by-name
  readCookie: (name) ->
    return null unless name

    value = "; " + document.cookie
    parts = value.split(";\\s*" + name + "=")
    if parts.length == 2
      JSON.parse decodeURIComponent parts.pop().split(/\s*;\s*/).shift()
    else
      null

  deleteCookie: (name) ->
    document.cookie = [name, '=; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/; domain=.', window.location.host.toString()].join('');

  activatePackage: (pkg, state) ->
    if pkg.frontend
      pkg.frontend({state, app: this})
      @emitter.emit 'did-activate-package', pkg

  activatePackages: ->
    state = @loadState() or {}

    for name, pkg of @packages
      @activatePackage(pkg, state[name])

    @emitter.emit 'did-activate-packages'

  onDidActivatePackages: (callback) ->
    @emitter.on 'did-activate-packages', callback

  onDidActivatePackage: (callback) ->
    @emitter.on 'did-activate-packages', callback


# Exports: Factory function for creating a bootstrap kit application
#
# See {BootstrapKitApp::constructor} for arguments
module.exports = (baseURL) ->
  new BootstrapKitApp(baseURL)
