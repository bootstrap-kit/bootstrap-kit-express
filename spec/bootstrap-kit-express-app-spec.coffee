if atom
  # need global "loophole", for browserify
  vm = require 'vm'
  global.eval = (source) ->
    vm.runInThisContext(source)
  global.Function = require('loophole').Function

bskExpressApp = require '../app.coffee'

describe 'bootstrap-kit-express-app', ->
  it 'can create an express app', ->
    bskeApp = bskExpressApp.makeApp()
    expect(typeof bskeApp.app.listen isnt 'undefined').toBe true

  it 'can create a frontend.js', ->
    waitsForPromise ->
      new Promise (resolve, reject) ->
        bskeApp = bskExpressApp.makeApp()
        bskeApp.createFrontend (error, result) ->
          if error
            reject(error)
          else
            console.log result.toString()
            resolve()

  describe 'server', ->
    bskeApp = null
    server  = null

    beforeEach ->
      bskeApp = bskExpressApp.makeApp()
      server = bskeApp.listen()

    afterEach ->
      server.close()

    it 'provides a frontend.js', ->

      waitsForPromise ->
        new Promise (resolve, reject) ->
          bskeApp.request "/frontend.js", (error, response, body) ->
            if error
              reject(error)
            else
              expect(response.statusCode).toBe(200)
              resolve()
