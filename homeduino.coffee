module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  _ = env.require('lodash')
  homeduino = require('homeduino')

  Board = homeduino.Board

  class HomeduinoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      #check transmitterPin and receiverPin
      if @config.driver is "serialport"
        unless @config.receiverPin in [0, 1]
          throw new Error("receiverPin must be 0 or 1")
        unless 2 <= @config.transmitterPin <= 13
          throw new Error("transmitterPin must be between 2 and 13")

      @board = new Board(@config.driver, @config.driverOptions)

      @board.on("data", (data) ->
        env.logger.debug("data: \"#{data}\"")
      )

      @board.on("rfReceive", (event) -> 
        env.logger.debug 'received:', event.pulseLengths, event.pulses
      )

      @board.on("rf", (event) -> 
        env.logger.debug "#{event.protocol}: ", event.values
      )

      @board.on("reconnect", (err) ->
        env.logger.debug "Couldn't connect (#{err.message}), retrying..."
      )

      @pendingConnect = @board.connect(@config.connectionTimeout).then( =>
        env.logger.info("Connected to homeduino device.")
        if @config.enableReceiving?
          @board.rfControlStartReceiving(@config.receiverPin).then( =>
            env.logger.debug("Receiving on pin #{@config.receiverPin}")
          ).catch( (err) =>
            env.logger.error("Couldn't start receiving: #{err.message}.")
            env.logger.debug(err.stack)
          )
        return
      ).catch( (err) =>
        env.logger.error("Couldn't connect to homeduino device: #{err.message}.")
        env.logger.error(err)
      )

      deviceConfigDef = require("./device-config-schema")

      deviceClasses = [
        HomeduinoDHTSensor
        HomeduinoRFSwitch
        HomeduinoRFTemperature
        HomeduinoRFPir
        HomeduinoRFGenericSensor
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (deviceConfig, lastState) => 
              device = new Cl(deviceConfig, lastState, @board, @config)
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


    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      super()

      lastError = null
      setInterval(( => 
        @_readSensor().then( (result) =>
          lastError = null
          @emit 'temperature', result.temperature
          @emit 'humidity', result.humidity
        ).catch( (err) =>
          if lastError is err.message
            env.logger.debug("Suppressing repeated error message from dht read: #{err.message}")
            return
          env.logger.error("Error reading DHT Sensor: #{err.message}.")
          lastError = err.message
        )
      ), @config.interval)
    
    _readSensor: (attempt = 0)-> 
      # Already reading? return the reading promise
      if @_pendingRead? then return @_pendingRead
      # Don't read the sensor to frequently, the minimal reading interal should be 2.5 seconds
      if @_lastReadResult?
        now = new Date().getTime()
        if (now - @_lastReadTime) < 2000
          return Promise.resolve @_lastReadResult
      @_pendingRead = @board.whenReady().then( =>
        return @board.readDHT(@config.type, @config.pin).then( (result) =>
          @_lastReadResult = result
          @_lastReadTime = (new Date()).getTime()
          @_pendingRead = null
          return result
        )
      ).catch( (err) =>
        @_pendingRead = null
        if (err.message is "checksum_error" or err.message is "timeout_error") and attempt < 5
          env.logger.debug "got #{err.message} while reading dht sensor, retrying: #{attempt} of 5"
          return Promise.delay(2500).then( => @_readSensor(attempt+1) )
        else
          throw err
      )
      
    getTemperature: -> @_readSensor().then( (result) -> result.temperature )
    getHumidity: -> @_readSensor().then( (result) -> result.humidity )

  class HomeduinoRFSwitch extends env.devices.PowerSwitch

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_state = lastState?.state?.value

      @_protocol = Board.getRfProtocol(@config.protocol)
      unless @_protocol?
        throw new Error("Could not find a protocol with the name \"#{@config.protocol}\".")
      unless @_protocol.type is "switch"
        throw new Error("\"#{@config.protocol}\" is not a switch protocol.")

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
        options = _.clone(@config.protocolOptions)
        unless options.all? then options.all = no
        options.state = state
        return @board.rfControlSendMessage(
          @_pluginConfig.transmitterPin, 
          @config.protocol, 
          options
        ).then( =>
          @_setState(state)
          return
        )
      )

  class HomeduinoRFPir extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_presence = lastState?.presence?.value

      @_protocol = Board.getRfProtocol(@config.protocol)
      unless @_protocol?
        throw new Error("Could not find a protocol with the name \"#{@config.protocol}\".")
      unless @_protocol.type is "pir"
        throw new Error("\"#{@config.protocol}\" is not a pir protocol.")

      resetPresence = ( =>
        @_setPresence(no)
      )

      @board.on('rf', (event) =>
        match = no
        if event.protocol is @config.protocol
          match = yes
          for optName, optValue of @config.protocolOptions
            #console.log "check", optName, optValue, event.values[optName]
            if event.values[optName] isnt optValue
              match = no
        if match
          unless @_setPresence is event.values.presence
            @_setPresence(event.values.presence)
          clearTimeout(@_resetPresenceTimeout)
          @_resetPresenceTimeout = setTimeout(resetPresence, @config.resetTime)
      )
      super()

    getPresence: -> Promise.resolve @_presence


  class HomeduinoRFTemperature extends env.devices.TemperatureSensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      @_temperatue = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value

      @_protocol = Board.getRfProtocol(@config.protocol)
      unless @_protocol?
        throw new Error("Could not find a protocol with the name \"#{@config.protocol}\".")
      unless @_protocol.type is "weather"
        throw new Error("\"#{@config.protocol}\" is not a weather protocol.")

      @attributes = {}

      if @_protocol.values.temperature?
        @attributes.temperature = {
          description: "the messured temperature"
          type: "number"
          unit: '°C'
        }
      if @_protocol.values.humidity?
        @attributes.humidity = {
          description: "the messured humidity"
          type: "number"
          unit: '%'
        }

      @board.on('rf', (event) =>
        match = no
        if event.protocol is @config.protocol
          match = yes
          for optName, optValue of @config.protocolOptions
            #console.log "check", optName, optValue, event.values[optName]
            if event.values[optName] isnt optValue
              match = no
        if match
          now = (new Date()).getTime()
          timeDelta = (
            if @_lastReceiveTime? then (now - @_lastReceiveTime)
            else 9999999
          )
          if timeDelta < 2000
            return 
          if @_protocol.values.temperature?
            @_temperatue = event.values.temperature
            # discard value if it is the same and was received just under two second ago
            @emit "temperature", @_temperatue
          if @_protocol.values.humidity?
            @_humidity = event.values.humidity
            # discard value if it is the same and was received just under two second ago
            @emit "humidity", @_humidity
          @_lastReceiveTime = now
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity

  class HomeduinoRFGenericSensor extends env.devices.Sensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name

      @_protocol = Board.getRfProtocol(@config.protocol)
      unless @_protocol?
        throw new Error("Could not find a protocol with the name \"#{@config.protocol}\".")
      unless @_protocol.type is "generic"
        throw new Error("\"#{@config.protocol}\" is not a generic protocol.")

      @attributes = {}
      for attributeConfig in @config.attributes
        @_createAttribute(attributeConfig)

      super()

      @_lastReceiveTimes = {}
      @board.on('rf', (event) =>
        match = no
        if event.protocol is @config.protocol
          match = yes
          for optName, optValue of @config.protocolOptions
            #console.log "check", optName, optValue, event.values[optName]
            if event.values[optName] isnt optValue
              match = no
        if match
          for attributeConfig in @config.attributes
            @_updateAttribute(attributeConfig, event)
      )
      super()

    _createAttribute: (attributeConfig) ->
      name = attributeConfig.name
      if @attributes[name]?
        throw new Error(
          "Two attributes with the same name in HomeduinoRFGenericSensor config \"#{name}\""
        )
      # Set description and label
      @attributes[name] = {
        description: name
        label: (
          if attributeConfig.label? and attributeConfig.label.length > 0 then attributeConfig.label 
          else name
        )
        type: "number"
      }
      # Set unit
      if attributeConfig.unit? and attributeConfig.unit.length > 0
        @attributes[name].unit = attributeConfig.unit
      # gnerate getter:
      @_createGetter(name, => Promise.resolve(@_attributesMeta[name].value))

    _updateAttribute: (attributeConfig, event) ->
      name = attributeConfig.name
      now = (new Date()).getTime()
      timeDelta = (
        if @_lastReceiveTimes[name]? then (now - @_lastReceiveTimes[name])
        else 9999999
      )
      if timeDelta < 2000
        return

      unless event.values.value?
        return

      unless event.values.type is attributeConfig.type
        return

      baseValue = attributeConfig.baseValue
      decimalsDivider = Math.pow(10, attributeConfig.decimals)
      value = event.values.value / decimalsDivider
      value = -value if event.values.positive is false
      value += baseValue
      @emit name, value
      @_lastReceiveTimes[name] = now

  hdPlugin = new HomeduinoPlugin()
  return hdPlugin