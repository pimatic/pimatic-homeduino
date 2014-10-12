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
  "driver": "serialport",
  "driverOptions": {
    "serialDevice": "/dev/ttyUSB0",
    "baudrate": 115200
  },
  "receiverPin": 0,
  "transmitterPin": 4
}
```

in the `plugins` section. For all configuration options see 
[homeduino-config-schema](homeduino-config-schema.coffee)

The pin numbers are arduino pin numbers. The `receiverPin` must be either `0` (INT0) or `1` (INT1).
The `transmitterPin` can must bq a digitial pin between `2` (D2) and `13` (D13) .

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

### PIR sensor example:

```json
{
      "id": "homeduino-pir",
      "name": "PIR",
      "class": "HomeduinoRFPir",
      "protocol": "pir1",
      "protocolOptions": {
        "unit": 0,
        "id": 17
      },
      "resetTime": 6000
}
```

### Generic RF Sensor with arduino sender

```json
{
  "id": "homeduino-generic-sensor",
  "name": "RFGenericSensor",
  "class": "HomeduinoRFGenericSensor",
  "protocol": "generic",
  "protocolOptions": {
    "id": 42
  },
  "attributes": [
    {
      "name": "temperature",
      "type": 10,
      "decimals": 2,
      "baseValue": 0,
      "unit": "°C",
      "label": "Temperature"
    }
  ]
}
```


TODO
----

*  Protocol documentation (options, ...)
