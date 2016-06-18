# Public: MainModule Class
#
# This class is rather a descriptive class to describe a {Package}'s main
# module.
#
# In some cases a package module can contain both: frontend and backend.
# If you need many backend packages or your frontend requires packages, which
# are incompatible for backend, you have to separate these modules.  Then you
# use frontend to specify a file to be loaded as frontend, having also this
# {MainModule} structure leaving out the backend part.
#
module.exports =
class MainModule

  # Public: frontend
  #
  # - `args` - {Object} with following keys:
  #   * `state` - {Object} state, which has been returned by {::serialize()}
  #   * `app`   - {BootstrapKitApp} object
  #
  # Load the frontend.  If this is a function, then this module will also be
  # included to browser (using browserify).
  #
  # Alternatively you can specify an absolute filename of a module, which
  # will be loaded for the frontend.  This file must also export a frontend
  # method for frontend loading.
  #
  frontend: ({state, app}) ->

  # Public: backend
  #
  # - `args` - {Object} with following keys:
  #   * `app`   - {BootstrapKitApp} object
  backend: ({app}) ->

  # Public: serialize
  #
  # Returns an object, which can be later passed into state to revive the
  # object.  This is used only in frontend.
  #
  serialize: ->
