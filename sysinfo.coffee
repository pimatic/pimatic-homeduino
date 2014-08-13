module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  ns = require('nsutil')
  Promise.promisifyAll(ns)

  class SysinfoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SystemSensor", {
        configDef: deviceConfigDef.SystemSensor, 
        createCallback: (config) => return new SystemSensor(config)
      })

    # ##LogWatcher Sensor
  class SystemSensor extends env.devices.Sensor

    constructor: (@config) ->
      @id = config.id
      @name = config.name

      @attributes = {}
      # initialise all attributes
      for attr, i in @config.attributes
        do (attr) =>
          name = attr.name
          assert name in ['cpu', 'memory']

          @attributes[name] = {
            description: name
            type: "number"
          }

          switch name
            when "cpu"
              lastCpuTimes = null
              sum = (cput) -> cput.user + cput.nice + cput.system + cput.idle
              reschredule = ( -> Promise.resolve().delay(1000).then( -> ns.cpuTimesAsync() ) )
              getter = ( => 
                return ns.cpuTimesAsync().then( (res) => 
                  if lastCpuTimes?
                    lastAll = sum(lastCpuTimes)
                    lastBusy = lastAll - lastCpuTimes.idle
                    all = sum(res)
                    busy = all - res.idle
                    busy_delta = busy - lastBusy
                    all_delta = all - lastAll
                    if all_delta is 0
                      return reschredule()
                    lastCpuTimes = res    
                    return Math.round(busy_delta / all_delta * 10000) / 100
                  else
                    lastCpuTimes = res
                    return reschredule();
                )
              )
              @attributes[name].unit = '%'
            when "memory"
              getter = ( =>
                return ns.virtualMemoryAsync().then( (res) =>
                  return Math.round( (res.total - res.avail) / (1014*1024) * 100) / 100
                )
              )
              @attributes[name].unit = 'MB'
            else
              throw new Error("Illegal attribute name: #{name} in SystemSensor.")
          # Create a getter for this attribute
          @_createGetter(name, getter)
          setInterval( (=>
            getter().then( (value) =>
              @emit name, value
            ).done()
          ), 2000)
      super()

  # ###Finally
  # Create a instance of my plugin
  sysinfoPlugin = new SysinfoPlugin
  # and return it to the framework.
  return sysinfoPlugin