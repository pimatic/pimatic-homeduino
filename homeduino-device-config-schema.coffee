module.exports = {
  title: "homedion device config schemes"
  HomeduinoDHTSensor: {
    title: "HomeduinoDHTSensor config options"
    type: "object"
    properties:
      type:
        description: "The type of the dht sensor (22, 33, 44 or 55)"
        type: "integer"
        default: 22
      pin: 
        description: "The digital pin, the DHT sensor is connected to."
        type: "integer"
    required: ["pin"]
  }
  HomedionKeypad: {
    title: "HomedionKeypad config options"
    type: "object"
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
  }
}