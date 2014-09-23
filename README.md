pimatic-homeduino
=======================

Plugin for using various 433mhz devices and sensors with a connected arduino with 
[homeduino](https://github.com/pimatic/homeduino) sketch.

This plugins supports all 433mhz devices with [rfcontroljs](https://github.com/pimatic/rfcontroljs) 
[protocol implementations](https://github.com/pimatic/rfcontroljs/blob/master/protocols.md).

![Hardware](hardware.jpg)  

Configuration
-------------
You can load the plugin by editing your `config.json` to include:

```json
{
  "plugin": "homeduino",
  "serialDevice": "/dev/ttyUSB0",
  "baudrate": 115200,
  "receiverPin": 0,
  "transmitterPin": 1
}
```

in the `plugins` section. For all configuration options see 
[homeduino-config-schema](homeduino-config-schema.coffee)

The pin numbers are arduino pin numbers. The `receiverPin` must be either `0` (INT0) or `1` (INT1).
The `transmitterPin` can be any digitial pin.

![nano-pins](pins-nano.png)

Devices must be added manually to the device section of your pimatic config. 

A list with all supported protocols and protocol-options can be found [here](https://github.com/pimatic/rfcontroljs/blob/master/protocols.md).

### weather-station sensor example:

```json
{
  "id": "rftemperature",
  "name": "Temperature",
  "class": "HomeduinoRFTemperature",
  "protocol": "weather2",
  "protocolOptions": {
    "id": 42,
    "channel": 1
  }
}
```

For protocol options see: 

### switch example:

```json
{
  "id": "rfswitch",
  "name": "RFSwitch",
  "class": "HomeduinoRFSwitch",
  "protocol": "switch1",
  "protocolOptions": {
    "id": 42,
    "unit": 0
  }
}
```

### DHT11/22 sensor example:

```json
{
  "id": "homeduino-temperature",
  "name": "DHT",
  "class": "HomeduinoDHTSensor",
  "type": 22,
  "pin": 13
}
```


TODO
----

*  Protocol documentation (options, ...)