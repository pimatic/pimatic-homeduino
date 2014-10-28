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
  HomeduinoRFSwitch: {
    title: "HomeduinoRFSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocol:
        description: "The switch protocol to use."
        type: "string"
      protocolOptions:
        description: "The protocol options"
        type: "object"
    required: ["protocol", "protocolOptions"]
  },
  HomeduinoRFSwitchMP: {
    title: "HomeduinoRFSwitchMP config options"
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
            protocol:
              type: "string"
            protocolOptions:
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
            #required: ["protocol", "protocolOptions"]
    required: ["protocols"]
  }
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
            protocol:
              description: "The switch protocol to use."
              type: "string"
            protocolOptions:
              description: "The protocol options"
              type: "object"
            required: ["protocol", "protocolOptions"]
  }
  HomeduinoRFContactSensor: {
    title: "HomeduinoRFContactSensor config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocol:
        description: "The contact protocol to use."
        type: "string"
      protocolOptions:
        description: "The protocol options"
        type: "object"
    required: ["protocol", "protocolOptions"]
  }
  HomeduinoRFShutter: {
    title: "HomeduinoRFSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      protocol:
        description: "The switch protocol to use."
        type: "string"
      protocolOptions:
        description: "The protocol options"
        type: "object"
    required: ["protocol", "protocolOptions"]
  }
  HomeduinoRFTemperature: {
    title: "HomeduinoRFTemperature config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      protocol:
        description: "The weather protocol to use."
        type: "string"
      protocolOptions:
        description: "The protocol options"
        type: "object"
    required: ["protocol", "protocolOptions"]
  }
  HomeduinoRFGenericSensor: {
    title: "HomeduinoRFGenericSensor config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      protocol:
        description: "The gernic protocol to use."
        type: "string"
        default: "generic"
      protocolOptions:
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
      protocol:
        description: "The switch protocol to use."
        type: "string"
      protocolOptions:
        description: "The protocol options"
        type: "object"
      resetTime:
        description: "Time after that the presence value is resettet to absent."
        type: "integer"
        default: 10
    required: ["protocol", "protocolOptions"]
  }
}
