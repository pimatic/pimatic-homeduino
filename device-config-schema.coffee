module.exports = {
  title: "Homeduino device config schemes"
  HomeduinoDHTSensor: {
    title: "HomeduinoDHTSensor config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      type:
        description: "The type of the DHT sensor (22, 33, 44 or 55)"
        type: "integer"
        default: 22
      pin:
        description: "The digital pin, the DHT sensor is connected to."
        type: "integer"
      interval:
        description: "Polling interval for the readings, should be greater than 2"
        type: "integer"
        default: 10000
      processingTemp:
        description: "
          expression that can preprocess the value, $value is a placeholder for the temperature
          value itself."
        type: "string"
        default: "$value"
      processingHum:
        description: "
          expression that can preprocess the value, $value is a placeholder for the humidity
          value itself."
        type: "string"
        default: "$value"
  },
  HomeduinoDSTSensor: {
    title: "HomeduinoDSTSensor config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      interval:
        description: "Polling interval for the readings, should be greater than 2"
        type: "integer"
        default: 10000
      pin:
        description: "The digital pin the DST sensor is connected to."
        type : "integer"
      address:
        description: "The address of the sensor"
        type: "string"
      processing:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
  },
  HomeduinoRFSwitch: {
    title: "HomeduinoRFSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocols:
        description: "The switch protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
            send:
              type: "boolean"
              description: "Toggle send with this protocol"
              default: true
            receive:
              type: "boolean"
              description: "Toggle receive with this protocol"
              default: true
            rfrepeats:
              type: "number"
              description: "The amount of RF repeats for this device"
              required: false
      forceSend:
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
  },
  HomeduinoRFDimmer: {
    title: "HomeduinoRFDimmer config options"
    type: "object"
    extensions: ["xConfirm"]
    properties:
      protocols:
        description: "The dimmer protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
            send:
              type: "boolean"
              description: "Toggle send with this protocol"
              default: true
            receive:
              type: "boolean"
              description: "Toggle receive with this protocol"
              default: true
            rfrepeats:
              type: "number"
              description: "The amount of RF repeats for this device"
              required: false
      forceSend:
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
  },
  HomeduinoRFButtonsDevice: {
    title: "HomeduinoRFButtonsDevice config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      buttons:
        description: "Buttons to display"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
            text:
              type: "string"
            protocols:
              description: "The protocols to use."
              type: "array"
              default: []
              format: "table"
              items:
                type: "object"
                properties:
                  name:
                    type: "string"
                  options:
                    description: "The protocol options"
                    type: "object"
                  send:
                    type: "boolean"
                    description: "Toggle send with this protocol"
                    default: true
                  receive:
                    type: "boolean"
                    description: "Toggle receive with this protocol"
                    default: true
                  rfrepeats:
                    type: "number"
                    description: "The amount of RF repeats for this device"
                    required: false
  }
  HomeduinoRFContactSensor: {
    title: "HomeduinoRFContactSensor config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xClosedLabel", "xOpenedLabel"]
    properties:
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      autoReset:
        description: """Reset the state after resetTime. Useful for contact sensors,
                      that only emit open or close events"""
        type: "boolean"
        default: false
      resetTime:
        description: """Time after that the contact state is reseted."""
        type: "integer"
        default: 10000
  }
  HomeduinoRFShutter: {
    title: "HomeduinoRFShutter config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
            send:
              type: "boolean"
              description: "Toggle send with this protocol"
              default: true
            receive:
              type: "boolean"
              description: "Toggle receive with this protocol"
              default: true
            rfrepeats:
              type: "number"
              description: "The amount of RF repeats for this device"
              required: false
      forceSend:
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
  }
  HomeduinoRFTemperature: {
    title: "HomeduinoRFTemperature config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      processingTemp:
        description: "
          expression that can preprocess the value, $value is a placeholder for the temperature
          value itself."
        type: "string"
        default: "$value"
      processingHum:
        description: "
          expression that can preprocess the value, $value is a placeholder for the humidity
          value itself."
        type: "string"
        default: "$value"
      isFahrenheit:
        description: "
          boolean that sets the right units if the temperature is to be reported in
           Fahrenheit"
        type: "boolean"
        default: false
  }
  HomeduinoRFWeatherStation: {
    title: "HomeduinoRFWeatherStation config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      values:
        type: "array"
        default: ["temperature", "humidity"]
        format: "table"
        items:
          type: "string"
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      processingTemp:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
      processingHum:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
      processingWindGust:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
      processingAvgAirspeed:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
      processingWindDirection:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
      processingRain:
        description: "
          expression that can preprocess the value, $value is a placeholder for the
          value itself."
        type: "string"
        default: "$value"
  }
  HomeduinoRFGenericSensor: {
    title: "HomeduinoRFGenericSensor config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      attributes:
        description: "The attributes (sensor values) of the sensor"
        type: "array"
        format: "table"
        items:
          type: "object"
          properties:
            name:
              description: "Name for the attribute."
              type: "string"
            type:
              description: "The type of this attribute in the rf message."
              type: "integer"
            decimals:
              description: "Decimals of the value in the rf message"
              type: "number"
              default: 0
            baseValue:
              description: "Offset that will be added to the value in the rf message"
              type: "number"
              default: 0
            unit:
              description: "The unit of the attribute"
              type: "string"
              default: ""
              required: false
            label:
              description: "A custom label to use in the frontend."
              type: "string"
              default: ""
              required: false
            discrete:
              description: "
                Should be set to true if the value does not change continuously over time.
              "
              type: "boolean"
              required: false
            acronym:
              description: "Acronym to show as value label in the frontend"
              type: "string"
              required: false
  }
  HomeduinoContactSensor: {
    title: "HomeduinoContactSensor config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xClosedLabel", "xOpenedLabel"]
    properties:
      inverted:
        description: "active low?"
        type: "boolean"
        default: false
      interval:
        description: "Time until the pin is read again."
        type: "integer"
        default: 10000
      pin:
        description: "Digital Pin number on the Arduino"
        type: "integer"
  }
  HomeduinoPir: {
    title: "HomeduinoPir config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      inverted:
        description: "active low?"
        type: "boolean"
        default: false
      interval:
        description: "Time until the pin is read again."
        type: "integer"
        default: 10000
      pin:
        description: "Digital Pin number on the Arduino"
        type: "integer"
  }
  HomeduinoAnalogSensor: {
    title: "HomeduinoAnalogSensor config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      attributes:
        description: "The attributes (sensor values) of the sensor"
        type: "array"
        format: "table"
        items:
          type: "object"
          properties:
            name:
              description: "Name for the attribute."
              type: "string"
            unit:
              description: "The unit of the attribute"
              type: "string"
              default: ""
            label:
              description: "A custom label to use in the frontend."
              type: "string"
              default: ""
            pin:
              description: "Arduino analog pin to read"
              type: "integer"
            interval:
              description: "The interval in which the analog pin should be read in ms"
              type: "integer"
              default: 5000
            processing:
              description: "
                expression that can preprocess the value, $value is a placeholder for the analog
                value itself."
              type: "string"
              default: "$value"
            discrete:
              description: "
                Should be set to true if the value does not change continuously over time.
              "
              type: "boolean"
              required: false
            acronym:
              description: "Acronym to show as value label in the frontend"
              type: "string"
              required: false

  }
  HomeduinoKeypad: {
    title: "HomeduinoKeypad config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      buttons:
        description: "Buttons of the keypad"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
            text:
              type: "string"
  },
  HomeduinoRFPir: {
    title: "HomeduinoRFPir config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      autoReset:
        description: """Reset the state after resetTime. Useful for pir sensors,
                      that emit present and absent events"""
        type: "boolean"
        default: true
      resetTime:
        description: "Time after that the presence value is reset to absent."
        type: "integer"
        default: 10000
  }
  HomeduinoSwitch: {
    title: "HomeduinoSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      pin:
        description: "The pin"
        type: "number"
      inverted:
        description: "active low?"
        type: "boolean"
        default: false
      defaultState:
        description: "State to set on startup, if not given, last state will be restored"
        type: "boolean"
        required: false
  },
  HomeduinoAnalogDimmer: {
    title: "HomeduinoAnalogDimmer config options"
    type: "object"
    extensions: ["xConfirm"]
    properties:
      pin:
        description: "The pin"
        type: "number"
      forceSend:
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
  },
}
