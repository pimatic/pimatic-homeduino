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

      @board.on("data", (data) ->
        env.logger.debug("data: \"#{data}\"")
      )

      @board.on("rfReceive", (event) -> 
        env.logger.debug 'received:', event.pulseLengths, event.pulses
      )

      @board.on("rf", (event) -> 
        env.logger.debug "#{event.protocol}: ", event.values
      )

      @pendingConnect = @board.connect().then( =>
        env.logger.info("Connected to homeduino device.")
        if @config.enableReceiving?
          @board.rfControlStartReceiving(@config.receiverPin).then( =>
            env.logger.debug("Receiving on pin #{@config.receiverPin}")
          ).catch( (err) =>
            env.logger.error("Couldn't start receiving: #{err.message}.")
          )
        return
      ).catch( (err) =>
        env.logger.error("Couldn't connect to homeduino device: #{err.message}.")
      )

      deviceConfigDef = require("./homeduino-device-config-schema")

      deviceClasses = [
        HomeduinoDHTSensor,
        HomeduinoRFSwitch,
        HomeduinoRFTemperature
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
      ), 10000)
    
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

  class HomeduinoRFSwitch extends env.devices.PowerSwitch

    constructor: (@config, @board) ->
      @id = config.id
      @name = config.name

      @board.on('rf', (event) =>
        match = no
        if event.protocol is @config.protocol
          match = yes
          for optName, optValue of @config.protocolOptions
            #console.log "check", optName, optValue, event.values[optName]
            if event.values[optName] isnt optValue
              match = no
        @_setState(event.values.state) if match
      )
      super()

    changeStateTo: (state) ->
      if @_state is state then return Promise.resolve true
      else return Promise.try( =>
        #todo: send...
        @_setState state
      )

  class HomeduinoRFTemperature extends env.devices.TemperatureSensor

    constructor: (@config, @board) ->
      @id = config.id
      @name = config.name

      @board.on('rf', (event) =>
        match = no
        if event.protocol is @config.protocol
          match = yes
          for optName, optValue of @config.protocolOptions
            #console.log "check", optName, optValue, event.values[optName]
            if event.values[optName] isnt optValue
              match = no
        if match
          temperature = event.values.temperature
          now = (new Date()).getTime()
          # discard value if it is the same and was received just under two second ago
          if @_lastReceiveTime?
            if temperature is @_temperatue and (now - @_lastReceiveTime) < 2000
              return
          @emit "temperature", temperature
          @_temperatue = temperature
          @_lastReceiveTime = now
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue

  hdPlugin = new HomeduinoPlugin()
  return hdPlugin