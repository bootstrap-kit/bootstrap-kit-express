pkgNum = 0

# Public: Package
#
# This class defines a package.
#
# A package is usually loaded with
module.exports =
class Package
  # Public: create a package object
  #
  # - `args` - {Object} with following keys:
  #   * `name` - {String} name of package
  #   * `mountpoint` - {String} mountpoint, where express app will be mounted
  #     in path
  #   * `mainModule` - {Module} module exporting an object matching
  #     {MainModule} objects
  constructor: (pkg) ->
    {@name, @mountpoint, @mainModule} = pkg
    unless @mainModule
      @mainModule = pkg
    unless @name
      @name = 'package-'+(pkgNum++)
