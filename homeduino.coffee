module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  class HomeduinoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Hello homeduino")

  # ###Finally
  # Create a instance of my plugin
  hdPlugin = new HomeduinoPlugin
  # and return it to the framework.
  return hdPlugin