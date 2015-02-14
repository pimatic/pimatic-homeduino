module.exports = {
  title: "homeduino device config schemes"
  HomeduinoDHTSensor: {
    title: "HomeduinoDHTSensor config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      type:
        description: "The type of the dht sensor (22, 33, 44 or 55)"
        type: "integer"
        default: 22
      pin: 
        description: "The digital pin, the DHT sensor is connected to."
        type: "integer"
      interval:
        description: "Polling interval for the readings, should be greater then 2"
        type: "integer"
        default: 10000
    required: ["pin"]
  },
  HomeduinoDSTSensor: {
    title: "HomeduinoDSTSensor config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      interval:
        description: "Polling interval for the readings, should be greater then 2"
        type: "integer"
        default: 10000
  },
  HomeduinoRFSwitch: {
    title: "HomeduinoRFSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocol:
        description: "The switch protocol to use."
        type: "string"
        default: ""
      protocolOptions:
        description: "The protocol options"
        type: "object"
        default: {}
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
      forceSend: 
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
    required: ["protocols"]
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
      forceSend: 
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
    required: ["protocols"]
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
            required: ["protocols"]
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
        description: """Reset the state after resetTime. Usefull for contact sensors, 
                      that only emit open or close events"""
        type: "boolean"
        default: false  
      resetTime:
        description: """Time after that the contact state is reseted."""
        type: "integer"
        default: 10000
    required: ["protocols"]
  }
  HomeduinoRFShutter: {
    title: "HomeduinoRFSwitch config options"
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
      forceSend: 
        type: "boolean"
        description: "Resend signal even if switch has the requested state already"
        default: true
    required: ["protocols"]
  }
  HomeduinoRFTemperature: {
    title: "HomeduinoRFTemperature config options"
    type: "object"
    extensions: ["xLink"]
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
    required: ["protocols"]
  }
  HomeduinoRFWeatherStation: {
    title: "HomeduinoRFWeatherStation config options"
    type: "object"
    extensions: ["xLink"]
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
    required: ["protocols"]
  }
  HomeduinoRFGenericSensor: {
    title: "HomeduinoRFGenericSensor config options"
    type: "object"
    extensions: ["xLink"]
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
              type: "integer"
              default: 0
            baseValue:
              description: "Offset that will be added to the value in the rf message"
              type: "number"
              default: 0
            unit:
              description: "The unit of the attribute"
              type: "string"
              default: ""
            label:
              description: "A custom label to use in the frontend."
              type: "string"
              default: ""

  }
  HomeduinoAnalogSensor: {
    title: "HomeduinoAnalogSensor config options"
    type: "object"
    extensions: ["xLink"]
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
              description: "The interval in whicht the analog pin should be read in ms"
              type: "integer"
              default: 5000
            processing: 
              description: "
                expression that can preprocess the value, $value is a placeholder for the analog 
                value itself."
              type: "string"
              default: "$value"

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
      resetTime:
        description: "Time after that the presence value is resettet to absent."
        type: "integer"
        default: 10000
    required: ["protocols"]
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
  }
}
