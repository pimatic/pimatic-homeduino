module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  _ = env.require('lodash')
  homeduino = require('homeduino')
  M = env.matcher

  Board = homeduino.Board

  class HomeduinoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      if @config.driver is "serialport"
        unless @config.receiverPin in [0, 1]
          throw new Error("receiverPin must be 0 or 1")
        unless 2 <= @config.transmitterPin <= 13
          throw new Error("transmitterPin must be between 2 and 13")

      @board = new Board(@config.driver, @config.driverOptions)

      @board.on("data", (data) =>
        if @config.debug
          env.logger.debug("data: \"#{data}\"")
      )

      @board.on("rfReceive", (event) => 
        if @config.debug
          env.logger.debug 'received:', event.pulseLengths, event.pulses
      )

      @board.on("rf", (event) =>  
        if @config.debug
          env.logger.debug "#{event.protocol}: ", event.values
      )

      @board.on("reconnect", (err) ->
        env.logger.warn "Couldn't connect (#{err.message}), retrying..."
      )

      @pendingConnect = new Promise( (resolve, reject) =>
        @framework.on "after init", ( =>
          @board.connect(@config.connectionTimeout).then( =>
            env.logger.info("Connected to homeduino device.")

            if @config.enableDSTSensors
              @board.readDstSensors(@config.dstSearchAddressPin).then( (ret) -> 
                env.logger.info("DST sensors: #{ret.sensors}")
              ).catch( (err) =>
                env.logger.error("Couldn't scan for DST sensors: #{err.message}.")
                env.logger.debug(err.stack)
              )

            if @config.enableReceiving
              @board.rfControlStartReceiving(@config.receiverPin).then( =>
                if @config.debug
                  env.logger.debug("Receiving on pin #{@config.receiverPin}")
              ).catch( (err) =>
                env.logger.error("Couldn't start receiving: #{err.message}.")
                env.logger.debug(err.stack)
              )
            return
          ).then(resolve).catch( (err) =>
            env.logger.error("Couldn't connect to homeduino device: #{err.message}.")
            env.logger.error(err.stack)
            reject(err)
          )
        )
      )
      
      # Enahnace the config schemes with available protocols, so we can build a better
      # gui for them
      protocols = _.cloneDeep(Board.getAllRfProtocols())
      for p in protocols
        supports = {
          temperature: p.values.temperature
          humidity: p.values.humidity
          state: p.values.state
          all: p.values.all
          battery: p.values.battery
          presence: p.values.presence
          lowBattery: p.values.lowBattery
        }
        for k, v of supports
          if v?
            delete p.values[k]
          else
            delete supports[k]
        for k, v of p.values
          v.type = "string" if v.type is "binary"
      availableProtocolOptions = {}
      for p in protocols
        availableProtocolOptions[p.name] = {
          type: "object"
          properties: p.values
        } 

      deviceConfigDef = require("./device-config-schema")

      deviceClasses = [
        HomeduinoDHTSensor
        HomeduinoDSTSensor
        HomeduinoRFSwitch
        HomeduinoRFDimmer
        HomeduinoRFButtonsDevice
        HomeduinoRFTemperature
        HomeduinoRFWeatherStation
        HomeduinoRFPir
        HomeduinoRFContactSensor
        HomeduinoRFShutter
        HomeduinoRFGenericSensor
        HomeduinoSwitch
        HomeduinoAnalogSensor
        HomeduinoContactSensor
      ]

      for Cl in deviceClasses
        do (Cl) =>
          dcd = deviceConfigDef[Cl.name]
          dcd.properties.protocols?.items?.properties?.name.defines = {
            property: "options"
            options: availableProtocolOptions
          }
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
            configDef: dcd
            createCallback: (deviceConfig, lastState) => 
              device = new Cl(deviceConfig, lastState, @board, @config)
              return device
          })

      @framework.ruleManager.addPredicateProvider(new RFEventPredicateProvider(@framework))

  hdPlugin = new HomeduinoPlugin()

  class HomeduinoDSTSensor extends env.devices.TemperatureSensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      super()

      lastError = null
      setInterval(( => 
        @_readSensor().then( (result) =>
          lastError = null
          variableManager = hdPlugin.framework.variableManager
          processing = @config.processing or "$value"
          info = variableManager.parseVariableExpression(
            processing.replace(/\$value\b/g, result.temperature)
          ) 
          variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
            @emit 'temperature', value
          )
          #@emit 'temperature', result.temperature
        ).catch( (err) =>
          if lastError is err.message
            if hdPlugin.config.debug
              env.logger.debug("Suppressing repeated error message from DST read: #{err.message}")
            return
          env.logger.error("Error reading DST Sensor: #{err.message}.")
          lastError = err.message
        )
      ), @config.interval)
    
    _readSensor: ()-> 
      # Already reading? return the reading promise
      if @_pendingRead? then return @_pendingRead
      # Don't read the sensor to frequently, the minimal reading interal should be 2.5 seconds
      if @_lastReadResult?
        now = new Date().getTime()
        if (now - @_lastReadTime) < 2000
          return Promise.resolve @_lastReadResult
      @_pendingRead = hdPlugin.pendingConnect.then( =>
        env.logger.debug("pin #{@config.pin}, address #{@config.address}")

        return @board.readDstSensor(@config.pin, @config.address).then( (result) =>
          @_lastReadResult = result
          @_lastReadTime = (new Date()).getTime()
          @_pendingRead = null
          return result
        )
      ).catch( (err) =>
        @_pendingRead = null
        throw err
      )
      
    getTemperature: -> @_readSensor().then( (result) -> result.temperature )

  #Original DHT implementation
  class HomeduinoDHTSensor extends env.devices.TemperatureSensor

    attributes:
      temperature:
        description: "the messured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      humidity:
        description: "the messured humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      super()

      lastError = null
      setInterval(( => 
        @_readSensor().then( (result) =>
          lastError = null
          variableManager = hdPlugin.framework.variableManager
          processing = @config.processingTemp or "$value"
          info = variableManager.parseVariableExpression(
            processing.replace(/\$value\b/g, result.temperature)
          ) 
          variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
            @emit 'temperature', value
          )
          #@emit 'temperature', result.temperature
          processing = @config.processingHum or "$value"
          info = variableManager.parseVariableExpression(
            processing.replace(/\$value\b/g, result.humidity)
          ) 
          variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
            @emit 'humidity', value
          )
          #@emit 'humidity', result.humidity
        ).catch( (err) =>
          if lastError is err.message
            if hdPlugin.config.debug
              env.logger.debug("Suppressing repeated error message from DHT read: #{err.message}")
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
      @_pendingRead = hdPlugin.pendingConnect.then( =>
        return @board.readDHT(@config.type, @config.pin).then( (result) =>
          @_lastReadResult = result
          @_lastReadTime = (new Date()).getTime()
          @_pendingRead = null
          return result
        )
      ).catch( (err) =>
        @_pendingRead = null
        if (err.message is "checksum_error" or err.message is "timeout_error") and attempt < 5
          if hdPlugin.config.debug
            env.logger.debug(
              "got #{err.message} while reading DHT sensor, retrying: #{attempt} of 5"
            )
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

  logDebug = (config, protocol, options) ->
    message = "Sending Protocol: #{protocol.name}"
    for field, content of options
      message += " #{field}: #{content}"
    message += " Pin: #{config.transmitterPin}
                Repeats: #{config.rfrepeats}"
    env.logger.debug(message)

  sendToSwitchesMixin = (protocols, state = null) ->
    pending = []
    for p in protocols
      do (p) =>
        unless p.send is false
          options = _.clone(p.options)
          unless options.all? then options.all = no
          options.state = state if state?
          pending.push hdPlugin.pendingConnect.then( =>
            if @_pluginConfig.debug
              logDebug(@_pluginConfig, p, options)
            return @board.rfControlSendMessage(
              @_pluginConfig.transmitterPin, 
              @_pluginConfig.rfrepeats,
              p.name, 
              options
            )
          )
    return Promise.all(pending)

  sendToDimmersMixin = (protocols, state = null, level = 0) ->
    pending = []
    for p in protocols
      do (p) =>
        unless p.send is false
          options = _.clone(p.options)
          unless options.all? then options.all = no
          options.state = state if state?
          _protocol = Board.getRfProtocol(p.name)
          if _protocol.values.dimlevel?
            min = _protocol.values.dimlevel.min
            max = _protocol.values.dimlevel.max
            level = Math.round(level / ((100 / (max - min)) + min))
          extend options, {dimlevel: level}
          if @_pluginConfig.debug
            logDebug(@_pluginConfig, p, options)
          pending.push hdPlugin.pendingConnect.then( =>
            return @board.rfControlSendMessage(
              @_pluginConfig.transmitterPin,
              @_pluginConfig.rfrepeats,
              p.name, 
              options
            )
          )
    return Promise.all(pending)

  extend = (obj, mixin) ->
    obj[name] = method for name, method of mixin        
    obj

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
            if p.name is "rolling1"
              if event.values.code in p.options.codeOn
                match = yes
                extend event.values, {state: on}
              else if event.values.code in p.options.codeOff
                match = yes
                extend event.values, {state: off}
              else match = no
            else
              match = doesProtocolMatch(event, p)

            if match
              @emit('rf', event) # used by the RFEventPredicateHandler
              @_setState(event.values.state) 
        )
      super()

    _sendStateToSwitches: sendToSwitchesMixin

    changeStateTo: (state) ->
      unless @config.forceSend
        if @_state is state then return Promise.resolve true
      @_sendStateToSwitches(@config.protocols, state).then( =>
        @_setState(state)
      )


  class HomeduinoRFDimmer extends env.devices.DimmerActuator
    _lastdimlevel: null

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or off
      
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "dimmer" or "switch"
          throw new Error("\"#{p.name}\" is not a dimmer or a switch protocol.")

      @board.on('rf', (event) =>
        for p in @config.protocols
          unless p.receive is false
            match = doesProtocolMatch(event, p)
            if match
              if event.values.state?
                if event.values.state is false
                  unless @_dimlevel is 0
                    @_lastdimlevel = @_dimlevel
                  @_setDimlevel(0)
                else
                  @_setDimlevel(@_lastdimlevel)
              else
                _protocol = Board.getRfProtocol(p.name)
                if _protocol.values.dimlevel?
                  min = _protocol.values.dimlevel.min
                  max = _protocol.values.dimlevel.max
                  dimlevel = Math.round(event.values.dimlevel * ((100.0 / (max - min))+min))
                  @_setDimlevel(dimlevel)
        )
      super()

    _sendLevelToDimmers: sendToDimmersMixin   

    turnOn: -> @changeDimlevelTo(@_lastdimlevel)

    changeDimlevelTo: (level) ->
      unless @config.forceSend
        if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = false
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel

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
          unless _protocol.type is "switch" or "command"
            throw new Error(
              "\"#{p.name}\" in config of button \"#{b.id}\" is not a switch or a command protocol."
            )
            
      @board.on('rf', (event) =>
        for b in @config.buttons
          unless b.receive is false
            match = no
            for p in b.protocols
              if doesProtocolMatch(event, p)
                match = yes
            if match
              @emit('button', b.id)
        )
  
      super(config)

    _sendStateToSwitches: sendToSwitchesMixin
    
    buttonPressed: (buttonId) ->
      for b in @config.buttons
        if b.id is buttonId
          @emit 'button', b.id
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
          if match
            hasContact = (
              if event.values.contact? then event.values.contact 
              else (not event.values.state)
            )
            @_setContact(hasContact)
            if @config.autoReset is true
              clearTimeout(@_resetContactTimeout)
              @_resetContactTimeout = setTimeout(( =>
                @_setContact(!hasContact)
              ), @config.resetTime)
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
      unless @config.forceSend
        if @_position is 'stopped' then return Promise.resolve()
      @_sendStateToSwitches(@config.protocols, @_position is 'up').then( =>
        @_setPosition('stopped')
      )
      
      return Promise.resolve()

    # Retuns a promise that is fulfilled when done.
    moveToPosition: (position) ->
      unless @config.forceSend
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
          throw new Error("\"#{p.name}\" is not a PIR protocol.")

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
            if @config.autoReset is true
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
      @_lowBattery = lastState?.lowBattery?.value
      @_battery = lastState?.battery?.value

      hasTemperature = false
      hasHumidity = false
      hasLowBattery = false # boolean battery indicator
      hasBattery = false # numeric battery indicator
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "weather"
          throw new Error("\"#{p.name}\" is not a weather protocol.")
        hasTemperature = true if _protocol.values.temperature?
        hasHumidity = true if _protocol.values.humidity?
        hasLowBattery = true if _protocol.values.lowBattery?
        hasBattery = true if  _protocol.values.battery?
      @attributes = {}

      if hasTemperature
        @attributes.temperature = {
          description: "the messured temperature"
          type: "number"
          unit: '°C'
          acronym: 'T'
        }
      if hasHumidity
        @attributes.humidity = {
          description: "the messured humidity"
          type: "number"
          unit: '%'
          acronym: 'RH'
        }

      if hasLowBattery
        @attributes.lowBattery = {
          description: "the battery status"
          type: "boolean"
          labels: ["low", 'ok']
          icon:
            noText: true
            mapping: {
              'icon-battery-filled': false
              'icon-battery-empy': true
            }
        }
      if hasBattery
        @attributes.battery = {
          description: "the battery status"
          type: "number"
          unit: '%'
          displaySparkline: false
          icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
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
            # discard value if it is the same and was received just under two second ago
            if timeDelta < 2000
              return 
            
            if event.values.temperature?
              variableManager = hdPlugin.framework.variableManager
              processing = @config.processingTemp or "$value"
              info = variableManager.parseVariableExpression(
                processing.replace(/\$value\b/g, event.values.temperature)
              ) 
              variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
                @_temperatue = value
                @emit "temperature", @_temperatue
              )
            if event.values.humidity?
              variableManager = hdPlugin.framework.variableManager
              processing = @config.processingHum or "$value"
              info = variableManager.parseVariableExpression(
                processing.replace(/\$value\b/g, event.values.humidity)
              ) 
              variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
                @_humidity = value
                @emit "humidity", @_humidity
              )
            if event.values.lowBattery?
              @_lowBattery = event.values.lowBattery
              @emit "lowBattery", @_lowBattery
            if event.values.battery?
              @_battery = event.values.battery
              @emit "battery", @_battery
            @_lastReceiveTime = now
      )
      super()

    getTemperature: -> Promise.resolve @_temperatue
    getHumidity: -> Promise.resolve @_humidity
    getLowBattery: -> Promise.resolve @_lowBattery
    getBattery: -> Promise.resolve @_battery

  class HomeduinoRFWeatherStation extends env.devices.Sensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      @_windGust = lastState?.windGust?.value or 0
      @_avgAirspeed = lastState?.avgAirspeed?.value or 0
      @_windDirection = lastState?.windDirection?.value or 0
      @_temperatue = lastState?.temperature?.value or 0
      @_humidity = lastState?.humidity?.value or 0
      @_rain = lastState?.rain?.value or 0

      hasWindGust = false
      hasAvgAirspeed = false
      hasWindDirection = false
      hasTemperature = false
      hasHumidity = false
      hasRain = false
      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")
        unless _protocol.type is "weather"
          throw new Error("\"#{p.name}\" is not a weather protocol.")
        hasRain = true if _protocol.values.rain?
        hasHumidity = true if _protocol.values.humidity?
        hasTemperature = true if _protocol.values.temperature?
        hasWindDirection = true if _protocol.values.windDirection?
        hasAvgAirspeed = true if _protocol.values.avgAirspeed?
        hasWindGust = true if _protocol.values.windGust?

      hasNoAttributes = (
        !hasRain and !hasHumidity and !hasTemperature and 
        !hasWindGust and !hasAvgAirspeed and !hasWindDirection
      )
      if hasNoAttributes
        throw new Error(
          "No values to show available. The config.protocols and the config.values doesn't match."
        )

      @attributes = {}

      for s in config.values
        switch s
          when "rain" 
            if hasRain
              if !@attributes.rain?
                @attributes.rain = {
                  description: "the measured fall of rain"
                  type: "number"
                  unit: 'mm'
                  acronym: 'RAIN'
                }
            else 
              env.logger.warn(
                "#{@id}: rain is defined but no protocol in config contains rain data!"
              )
          when "humidity"
            if hasHumidity
              if !@attributes.humidity?
                @attributes.humidity = {
                  description: "the messured humidity"
                  type: "number"
                  unit: '%'
                  acronym: 'RH'
                }
            else 
              env.logger.warn(
                "#{@id}: humidity is defined but no protocol in config contains humidity data!"
              )
          when "temperature"
            if hasTemperature
              if !@attributes.temperature?
                @attributes.temperature = {
                  description: "the messured temperature"
                  type: "number"
                  unit: '°C'
                  acronym: 'T'
                }
            else 
              env.logger.warn(
                "#{@id}: temperature is defined but no protocol in config contains " +
                "temperature data!"
              )
          when "windDirection"
            if hasWindDirection
              if !@attributes.windDirection?
                @attributes.windDirection = {
                  description: "the messured wind direction"
                  type: "string"
                  acronym: 'WIND'
                }
            else 
              env.logger.warn(
                "#{@id}: windDirection is defined but no protocol in config contains " +
                "windDirection data!"
              )
          when "avgAirspeed"
            if hasAvgAirspeed
              if !@attributes.avgAirspeed?
                @attributes.avgAirspeed = {
                  description: "the measured average airspeed"
                  type: "number"
                  unit: 'm/s'
                  acronym: 'SPEED'
                }
            else 
              env.logger.warn(
                "#{@id}: avgAirspeed is defined but no protocol in config contains " + 
                "avgAirspeed data!"
              ) 
          when "windGust"
            if hasWindGust
              if !@attributes.windGust?
                @attributes.windGust = {
                  description: "the measured wind gust"
                  type: "number"
                  unit: 'm/s'
                  acronym: 'GUST'
                }
            else 
              env.logger.warn(
                "#{@id}: windGust is defined but no protocol in config contains windGust data!"
              ) 
          else 
            throw new Error(
              "Values should be one of: " + 
              "rain, humidity, temperature, windDirection, avgAirspeed, windGust"
            )

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
            if event.values.windGust?
              @_windGust = event.values.windGust
              # discard value if it is the same and was received just under two second ago
              @emit "windGust", @_windGust
            if event.values.avgAirspeed?
              @_avgAirspeed = event.values.avgAirspeed
              # discard value if it is the same and was received just under two second ago
              @emit "avgAirspeed", @_avgAirspeed
            if event.values.windDirection?
              @_windDirection = event.values.windDirection
              # discard value if it is the same and was received just under two second ago
              dir = @_directionToString(@_windDirection)
              @emit "windDirection", "#{@_windDirection}°(#{dir})"
            if event.values.temperature?
              @_temperatue = event.values.temperature
              # discard value if it is the same and was received just under two second ago
              @emit "temperature", @_temperatue
            if event.values.humidity?
              @_humidity = event.values.humidity
              # discard value if it is the same and was received just under two second ago
              @emit "humidity", @_humidity
            if event.values.rain?
              @_rain = event.values.rain
              # discard value if it is the same and was received just under two second ago
              @emit "rain", @_rain
            @_lastReceiveTime = now
      )
      super()

    _directionToString: (direction)->
      if direction<=360 and direction>=0
        direction = Math.round(direction / 45)
        labels = ["N","NE","E","SE","S","SW","W","NW","N"]
      return labels[direction]

    getWindDirection: -> Promise.resolve @_windDirection
    getAvgAirspeed: -> Promise.resolve @_avgAirspeed
    getWindGust: -> Promise.resolve @_windGust
    getRain: -> Promise.resolve @_rain
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
        
      if attributeConfig.discrete?
        @attributes[name].discrete = attributeConfig.discrete

      if attributeConfig.acronym?
        @attributes[name].acronym = attributeConfig.acronym

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

  class HomeduinoSwitch extends env.devices.PowerSwitch

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name

      if @config.defaultState?
        @_state = @config.defaultState
      else
        @_state = lastState?.state?.value or off

      hdPlugin.pendingConnect.then( =>
        return @board.pinMode(@config.pin, Board.OUTPUT)
      ).then( => 
        return @_writeState(@_state)
      ).catch( (error) =>
        env.logger.error error
        env.logger.debug error.stack
      )
      super()

    getState: () -> Promise.resolve @_state

    _writeState: (state) ->
      if @config.inverted then _state = not state
      else _state = state
      return hdPlugin.pendingConnect.then( =>
        return @board.digitalWrite(@config.pin, if _state then Board.HIGH else Board.LOW)
      )
        
    changeStateTo: (state) ->
      assert state is on or state is off
      return @_writeState(state).then( =>
        @_setState(state)
      )

  class HomeduinoContactSensor extends env.devices.ContactSensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name
      @_contact = lastState?.contact?.value or false

      # setup polling
      hdPlugin.pendingConnect.then( => 
        return @board.pinMode(@config.pin, Board.INPUT) 
      ).then( => 
        requestContactValue = =>
          @board.digitalRead(@config.pin).then( (value) =>
            hasContact = (
              if value is Board.HIGH then !@config.inverted 
              else @config.inverted
            )
            @_setContact(hasContact)
          ).catch( (error) =>
            env.logger.error error
            env.logger.debug error.stack
          )
          setTimeout(requestContactValue, @config.interval or 5000)
        requestContactValue()
      ).catch( (error) =>
        env.logger.error error
        env.logger.debug error.stack
      )
      super()

  class HomeduinoAnalogSensor extends env.devices.Sensor

    constructor: (@config, lastState, @board) ->
      @id = config.id
      @name = config.name

      @attributes = {}
      for attributeConfig in @config.attributes
        @_createAttribute(attributeConfig)
      super()

    _createAttribute: (attributeConfig) ->
      name = attributeConfig.name
      if @attributes[name]?
        throw new Error(
          "Two attributes with the same name in HomeduinoAnalogSensor config \"#{name}\""
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

      if attributeConfig.discrete?
        @attributes[name].discrete = attributeConfig.discrete

      if attributeConfig.acronym?
        @attributes[name].acronym = attributeConfig.acronym
                 
      # gnerate getter:
      @_createGetter(name, => Promise.resolve(@_attributesMeta[name].value))

      # setup polling
      hdPlugin.pendingConnect.then( => 
        return @board.pinMode(attributeConfig.pin, Board.INPUT) 
      ).then( => 
        variableManager = hdPlugin.framework.variableManager
        processing = attributeConfig.processing or "$value"
        requestAttributeValue = =>
          @board.analogRead(attributeConfig.pin).then( (value) =>
            info = variableManager.parseVariableExpression(processing.replace(/\$value\b/g, value)) 
            variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
              @_attributesMeta[name].value = value
              @emit name, value
            )
          ).catch( (error) =>
            env.logger.error error
            env.logger.debug error.stack
          )
          setTimeout(requestAttributeValue, attributeConfig.interval or 5000)
        requestAttributeValue()
      ).catch( (error) =>
        env.logger.error error
        env.logger.debug error.stack
      )

  ###
  The RF-Event Predicate Provider
  ----------------
  Provides predicates for the state of switch devices like:

  * _device_ receives on|off

  ####
  class RFEventPredicateProvider extends env.predicates.PredicateProvider

    constructor: (@framework) ->

    # ### parsePredicate()
    parsePredicate: (input, context) ->  

      rfSwitchDevices = _(@framework.deviceManager.devices)
        .filter( (device) => device instanceof HomeduinoRFSwitch ).value()

      device = null
      state = null
      match = null

      M(input, context)
        .matchDevice(rfSwitchDevices, (next, d) =>
          next.match([' receives'])
            .match([' on', ' off'], (next, s) =>
              # Already had a match with another device?
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              assert d?
              assert s in [' on', ' off']
              device = d
              state = s.trim() is 'on'
              match = next.getFullMatch()
          )
        )
 
      # If we have a match
      if match?
        assert device?
        assert state?
        assert typeof match is "string"
        # and state as boolean.
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new RFEventPredicateHandler(device, state)
        }
      else
        return null

  class RFEventPredicateHandler extends env.predicates.PredicateHandler

    constructor: (@device, @state) ->
    setup: ->
      lastTime = 0
      @rfListener = (event) => 
        if @state is event.values.state
          now = new Date().getTime()
          # suppress same values within 200ms
          if now - lastTime <= 200
            return
          lastTime = now
          @emit 'change', 'event' 
      @device.on 'rf', @rfListener
      super()
    getValue: -> Promise.resolve(false)
    destroy: -> 
      @device.removeListener "rf", @rfListener
      super()
    getType: -> 'event'

  return hdPlugin
