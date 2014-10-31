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
        env.logger.error(err.stack)
      )

      deviceConfigDef = require("./device-config-schema")

      deviceClasses = [
        HomeduinoDHTSensor
        HomeduinoRFSwitch
        HomeduinoRFDimmer
        HomeduinoRFButtonsDevice
        HomeduinoRFTemperature
        HomeduinoRFPir
        HomeduinoRFContactSensor
        HomeduinoRFShutter
        HomeduinoRFGenericSensor
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            prepareConfig: (config) =>
              # legacy support for old configs (with just one protocol):
              if config.protocol? and config.protocolOptions?
                config.protocols = [
                  { name: config.protocol, options: config.protocolOptions}
                ]
                delete config.protocol
                delete config.protocolOptions
              if config['class'] is "HomeduinoRFButtonsDevice"
                for b in config.buttons
                  if b.protocol? and b.protocolOptions
                    b.protocols = [
                      { name: b.protocol, options: b.protocolOptions}
                    ]
                    delete b.protocol
                    delete b.protocolOptions
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


  doesProtocolMatch = (event, protocol) ->
    match = no
    if event.protocol is protocol.name
      match = yes
      for optName, optValue of protocol.options
        #console.log "check", optName, optValue, event.values[optName]
        unless optName is "unit" and event.values.all is true
          if event.values[optName] isnt optValue
            match = no
    return match

  sendToSwitchesMixin = (protocols, state = null) ->
    pending = []
    for p in protocols
      unless p.send is false
        options = _.clone(p.options)
        unless options.all? then options.all = no
        options.state = state if state?
        pending.push @board.rfControlSendMessage(
          @_pluginConfig.transmitterPin, 
          p.name, 
          options
        )
    return Promise.all(pending)

  sendToDimmersMixin = (protocols, state = null, level = 0) ->
    pending = []
    for p in protocols
      unless p.send is false
        options = _.clone(p.options)
        unless options.all? then options.all = no
        options.state = state if state?
        _protocol = Board.getRfProtocol(p.name)
        dimlevel = Math.round(level / ((100 / (_protocol.values.dimlevel.max - _protocol.values.dimlevel.min))+_protocol.values.dimlevel.min))
        message = 
          id: options.id
          all: options.all
          state: options.state
          unit: options.unit
          dimlevel: dimlevel
        pending.push @board.rfControlSendMessage(
          @_pluginConfig.transmitterPin, 
          p.name, 
          message
        )
    return Promise.all(pending)

  class HomeduinoRFSwitch extends env.devices.PowerSwitch

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_state = lastState?.state?.value
      
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "switch"
          throw new Error("\"#{p.name}\" is not a switch protocol.")

      @board.on('rf', (event) =>
        for p in @config.protocols
          unless p.receive is false
            match = doesProtocolMatch(event, p)
            @_setState(event.values.state) if match
        )
      super()

    _sendStateToSwitches: sendToSwitchesMixin

    changeStateTo: (state) ->
      if @_state is state then return Promise.resolve true
      else 
        @_sendStateToSwitches(@config.protocols, state).then( =>
          @_setState(state)
        )

  class HomeduinoRFDimmer extends env.devices.DimmerActuator

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_state = lastState?.state?.value or off
      
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "dimmer"
          throw new Error("\"#{p.name}\" is not a dimmer protocol.")

      @board.on('rf', (event) =>
        for p in @config.protocols
          unless p.receive is false
            match = doesProtocolMatch(event, p)
            if match
              _protocol = Board.getRfProtocol(p.name)
              dimlevel = Math.round(event.values.dimlevel * ((100.0 / (_protocol.values.dimlevel.max - _protocol.values.dimlevel.min))+_protocol.values.dimlevel.min))
              @_setDimlevel(dimlevel)
        )
      super()

    _sendLevelToDimmers: sendToDimmersMixin

    changeDimlevelTo: (level) ->
      if @_dimlevel is level then return Promise.resolve true
      else
        state = false
        if level > 0 then state = true
        @_sendLevelToDimmers(@config.protocols, state, level).then( =>
          @_setDimlevel(level)
        )
  
  class HomeduinoRFButtonsDevice extends env.devices.ButtonsDevice

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name

      for b in config.buttons
        for p in b.protocols
          _protocol = Board.getRfProtocol(p.name)
          unless _protocol?
            throw new Error(
              "Could not find a protocol with the name \"#{p.name}\" in config" +
              " of button \"#{b.id}\"."
            )
          unless _protocol.type is "switch"
            throw new Error(
              "\"#{p.name}\" in config of button \"#{b.id}\" is not a switch protocol."
            )
      super(config)

    _sendStateToSwitches: sendToSwitchesMixin

    buttonPressed: (buttonId) ->
      for b in @config.buttons
        if b.id is buttonId
          return @_sendStateToSwitches(b.protocols)
      throw new Error("No button with the id #{buttonId} found")
      

  class HomeduinoRFContactSensor extends env.devices.ContactSensor

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_contact = lastState?.contact?.value or false

      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")

      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
          @_setContact(not event.values.state) if match
      )
      super()

  class HomeduinoRFShutter extends env.devices.ShutterController

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_position = lastState?.position?.value or 'stopped'

      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")

      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
          unless match
            return
          now = new Date().getTime()
          # ignore own send messages
          if (now - @_lastSendTime) < 3000
            return
          if @_position is 'stopped'
            @_setPosition(if event.values.state then 'up' else 'down')
          else
            @_setPosition('stopped')
      )
      super()

    _sendStateToSwitches: sendToSwitchesMixin

    stop: ->
      if @_position is 'stopped' then return Promise.resolve()
      @_sendStateToSwitches(@config.protocols, @_position is 'up').then( =>
        @_setPosition('stopped')
      )
      
      return Promise.resolve()

    # Retuns a promise that is fulfilled when done.
    moveToPosition: (position) ->
      if position is @_position then return Promise.resolve()
      if position is 'stopped' then return @stop()
      else return @_sendStateToSwitches(@config.protocols, position is 'up').then( =>
        @_lastSendTime = new Date().getTime()
        @_setPosition(position)
      )



  class HomeduinoRFPir extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_presence = lastState?.presence?.value or false

      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "pir"
          throw new Error("\"#{p.name}\" is not a pir protocol.")

      resetPresence = ( =>
        @_setPresence(no)
      )

      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
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

      hasTemperature = false
      hasHumidity = false
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "weather"
          throw new Error("\"#{p.name}\" is not a weather protocol.")
        hasTemperature = true if _protocol.values.temperature?
        hasHumidity = true if _protocol.values.humidity?

      @attributes = {}

      if hasTemperature
        @attributes.temperature = {
          description: "the messured temperature"
          type: "number"
          unit: '°C'
        }
      if hasHumidity
        @attributes.humidity = {
          description: "the messured humidity"
          type: "number"
          unit: '%'
        }

      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
          if match
            now = (new Date()).getTime()
            timeDelta = (
              if @_lastReceiveTime? then (now - @_lastReceiveTime)
              else 9999999
            )
            if timeDelta < 2000
              return 
            if event.values.temperature?
              @_temperatue = event.values.temperature
              # discard value if it is the same and was received just under two second ago
              @emit "temperature", @_temperatue
            if event.values.humidity?
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

      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "generic"
          throw new Error("\"#{p.name}\" is not a generic protocol.")

      @attributes = {}
      for attributeConfig in @config.attributes
        @_createAttribute(attributeConfig)

      super()

      @_lastReceiveTimes = {}
      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
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
