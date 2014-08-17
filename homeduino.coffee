module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  homeduino = require('homeduino')
  Board = homeduino.Board

  class HomeduinoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @board = new Board(@config.serialDevice, @config.baudrate)
      @pendingConnect = @board.connect().then( ->
        env.logger.info("Connected to homeduino device.")
      ).catch( (err) ->
        env.logger.error("Couldn't connect to homeduino device: #{err.message}.")
      )

      deviceConfigDef = require("./homeduino-device-config-schema")

      deviceClasses = [
        HomeduinoDHTSensor
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (deviceConfig) => 
              device = new Cl(deviceConfig, @board)
              return device
          })

  # Homed controls FS20 devices
  class HomeduinoDHTSensor extends env.devices.TemperatureSensor

    attributes:
      temperature:
        description: "the messured temperature"
        type: "number"
        unit: '°C'
      humidity:
        description: "the messured humidity"
        type: "number"
        unit: '%'


    constructor: (@config, @board) ->
      @id = config.id
      @name = config.name
      super()

      setInterval(( => 
        @_readSensor().then( (result) =>
          @emit 'temperature', result.temperature
          @emit 'humidity', result.humidity
        ).catch( (err) =>
          env.logger.error("Error reading DHT Sensor: #{err.message}.")
        )
      ), 5000)
    
    _readSensor: -> 
      # Already reading? return the reading promise
      if @_pendingRead? then return @_pendingRead
      # Don't read the sensor to frequently, the minimal reading interal should be 2 seconds
      if @_lastReadResult?
        now = new Date().getTime()
        if (now - @_lastReadTime) < 2000
          return @_lastReadResult
      @_pendingRead = @board.whenReady().then( =>
        return @board.readDHT(@config.type, @config.pin).then( (result) =>
          @_lastReadResult = result
          @_lastReadTime = (new Date()).getTime()
          @_pendingRead = null
          return result
        )
      )
      
    getTemperature: -> @_readSensor().then( (result) -> result.temperature )
    getHumidity: -> @_readSensor().then( (result) -> result.humidity )


  hdPlugin = new HomeduinoPlugin()
  return hdPlugin