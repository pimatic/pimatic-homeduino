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
      default: 115200
    enableReceiving:
      description: "Enable the receiving of 433mhz rf signals?"
      type: "boolean"
      default: true
    receiverPin:
      description: "The arduino interrupt pin, the 433mhz receiver is connected to."
      type: "integer"
      default: 0
    transmitterPin:
      description: "The arduino digital pin, the 433mhz transmitter is connected to."
      type: "integer"
      default: 3
    connectionTimeout: 
      description: "Time to wait for ready package on connection"
      type: "integer"
      default: 60000
}
