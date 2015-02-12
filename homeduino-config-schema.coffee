# #homeduino configuration options
module.exports = {
  title: "homeduino config"
  type: "object"
  properties:
    driver:
      description: "The diver to connect to the arduino or virtualarduino"
      type: "string"
      enum: ["serialport", "gpio"]
      default: "serialport"
    driverOptions:
      description: "Options for the driver"
      type: "object"
      default: {
        "serialDevice": "/dev/ttyUSB0",
        "baudrate": 115200
      }
      # oneOf: [
      #   {
      #     title: "serialport driver options"
      #     properties:
      #       serialDevice:
      #         description: "The name of the serial device to use"
      #         type: "string"
      #         default: "/dev/ttyUSB0"
      #       baudrate:
      #         description: "The baudrate to use for serial communication"
      #         type: "integer"
      #         default: 115200
      #   },
      #   {
      #     properties: {}
      #   }
      #]
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
      default: 4
    connectionTimeout: 
      description: "Time to wait for ready package on connection"
      type: "integer"
      default: 5*60*1000 # 5min
    debug:
      description: "log information for debugging including received messages"
      type: "boolean"
      default: true
}
