# #homeduino configuration options
module.exports = {
  title: "homeduino config"
  type: "object"
  properties:
    serialDevice:
      description: "The name of the serial device to use"
      type: "string"
      default: "/dev/ttyUSB0"
    baudrate:
      description: "The baudrate to use for serial communication"
      type: "integer"
      default: 9600
}
