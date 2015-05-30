pimatic-homeduino
=======================

Plugin for using various 433 Mhz devices and sensors with a connected Arduino with 
[homeduino](https://github.com/pimatic/homeduino) sketch or directly with capable hardware like the Raspberry Pi.

This plugins supports all 433 MHz devices with [rfcontroljs](https://github.com/pimatic/rfcontroljs) 
[protocol implementations](https://github.com/pimatic/rfcontroljs/blob/master/protocols.md).


Drivers
------

The plugin can be used with two different hardware combinations:

*  A. Computer with connected Arduino (with homeduino sketch) and 433 MHz transmitter and receiver (recommended)
*  B. Raspberry Pi (or Banana Pi or Hummingboard) with 433 MHz transmitter and receiver


### A.Connected Arduino (recommended)

![Hardware](https://raw.githubusercontent.com/pimatic/pimatic-homeduino/master/hardware.jpg)  

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
  "transmitterPin": 4,
  "dstSearchAddressPin": 12
}
```

in the `plugins` section. For all configuration options see [homeduino-config-schema](homeduino-config-schema.coffee)

The pin numbers are Arduino pin numbers. The `receiverPin` must be either `0` (INT0) or `1` (INT1).
The `transmitterPin` must be a digitial pin between `2` (D2) and `13` (D13).

![nano-pins](https://raw.githubusercontent.com/pimatic/pimatic-homeduino/master/pins-nano.png)


### B. Raspberry Pi with ATTiny45 / 85 Prefilter

You can load the plugin by editing your `config.json` to include:

```json
{
  "plugin": "homeduino",
  "driver": "gpio",
  "driverOptions": {},
  "receiverPin": 0,
  "transmitterPin": 4
}
```

in the `plugins` section. For all configuration options see [homeduino-config-schema](homeduino-config-schema.coffee)

The pin numbers are [wiringPi pin numbers](http://wiringpi.com/pins/).

Devices
------

Devices must be added manually to the device section of your pimatic config. 

A list with all supported protocols and protocol-options can be found [here](https://github.com/pimatic/rfcontroljs/blob/master/protocols.md).

### Weather station sensor example:

This is the basic sensor with only temperature and humidity
```json
{
  "id": "rftemperature",
  "name": "Temperature",
  "class": "HomeduinoRFTemperature",
  "protocols": [{
    "name": "weather2",
    "options": {
      "id": 42,
      "channel": 1
    }
  }]
}
```
For weather stations like the Alecto WS-4500 you should use the weather station device
```json
{
  "id": "weatherstation",
  "name": "Weather Data",
  "class": "HomeduinoRFWeatherStation",
  "protocols": [
    {
      "name": "weather5",
      "options": {
        "id": 120
      }
    }
  ],
  "values": [
    "rain",
    "temperature",
    "humidity"
  ]
},
```
It supports different values to display
rain, temperature, humidity, windGust, windDirection and avgAirspeed
The order of the listed values define the order of the displayed values.

 

### Switch example:

```json
{
  "id": "rfswitch",
  "name": "RFSwitch",
  "class": "HomeduinoRFSwitch",
  "protocols": [{
    "name": "switch1",
    "options": {
      "id": 42,
      "unit": 0
    }
  }]
}
```

A switch (and other devices) can be controlled or send to outlets with multiple protocols. Just
add more protocols to the `protocols` array. You can also set if a protocol
is used for sending or receiving. Default is `true` for both.

### Multi protocol switch example:

```json
    {
      "id": "switchmp",
      "name": "Multi Switch",
      "class": "HomeduinoRFSwitch",
      "protocols": [
        {
          "name": "switch1",
          "options": {
            "id": 9509718,
            "unit": 0
          },
          "send": true,
          "receive": true
        },
        {
          "name": "switch1",
          "options": {
            "id": 9509718,
            "unit": 1
          },
          "send": false,
          "receive": true
        }
      ]
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

### DST Dallas DS18B20 sensor example:

```json
{
  "id": "homeduino-temperature-dst",
  "name": "DST",
  "class": "HomeduinoDSTSensor",
  "pin": 12,
  "address" : "104AE9B50008000E",
  "interval" : 10000
}
```

### PIR sensor example:

```json
{
  "id": "homeduino-pir",
  "name": "PIR",
  "class": "HomeduinoRFPir",
  "protocols": [{
    "name": "pir1",
    "options": {
      "unit": 0,
      "id": 17
    }
  }],
  "resetTime": 6000
}
```

### Contact sensor example:

```json
{
  "id": "homeduino-contact",
  "name": "Contact",
  "class": "HomeduinoRFContactSensor",
  "protocols": [{
    "name": "contact1",
    "options": {
      "unit": 0,
      "id": 42
    }
  }]
}
```

Some contacts only emit an event on open. For this you can set autoReset to true:

```json
{
  "id": "door-contact",
  "name": "door-Contact",
  "class": "HomeduinoRFContactSensor",
  "protocols": [
    {
      "name": "contact2",
      "options": {
        "id": 43690
      }
    }
  ],
  "autoReset": true,
  "resetTime": 3000
}
```

### Shutter sensor example:

*Can use switch protocols.*

```json
{
  "id": "homeduino-contact",
  "name": "Shutter Controller",
  "class": "HomeduinoRFShutter",
  "protocols": [{
    "name": "switch1",
    "options": {
      "unit": 0,
      "id": 42
    }
  }]
}
```


### Generic RF Sensor with Arduino sender

```json
{
  "id": "homeduino-generic-sensor",
  "name": "RFGenericSensor",
  "class": "HomeduinoRFGenericSensor",
  "protocols": [{
    "name": "generic",
    "options": {
      "id": 42
    }
  }],
  "attributes": [
    {
      "name": "temperature",
      "type": 3,
      "decimals": 2,
      "baseValue": 0,
      "unit": "°C",
      "label": "Temperature"
    }
  ]
}
```

### Buttons Device example:

```json
{
  "id": "homeduino-buttons",
  "name": "Buttons",
  "class": "HomeduinoRFButtonsDevice",
  "buttons": [
    {
      "id": "test-button",
      "text": "test",
      "protocols": [{
        "name": "switch1",
        "options": {
          "unit": 0,
          "id": 42,
          "state": true
        }
      }]
    }
  ]
}
```

### Dimmer device example:
```json
{
  "id": "dimmer",
  "name": "Dimmer",
  "class": "HomeduinoRFDimmer",
  "protocols": [
    {
      "name": "dimmer1",
      "options": {
        "id": 7654321,
        "unit": 0
      },
      "send": true,
      "receive": true
    }
  ]
},
```
### Pin switch example:

```json
{
  "id": "pin-switch",
  "name": "Pin Switch",
  "class": "HomeduinoSwitch",
  "inverted": false,
  "pin": 13
}
```

### AnalogSensor example:

An AnalogSensor can read analog pins of the Arduino and display there value. 
An optional preprocessing can be applied. Pin numbering starts at 14 (`A0`) 
for the first analog pin.

```json
{
  "id": "homeduino-analog-sensor",
  "name": "AnalogSensor",
  "class": "HomeduinoAnalogSensor",
  "attributes": [
    {
      "name": "voltage",
      "unit": "V",
      "label": "Voltage",
      "pin": 14,
      "interval": 5000,
      "processing": "($value / 1023) * 5"
    }
  ]
}
```

The analog value is between 0 and 1023 and can be preprocessed by an expression. In this example
the value is scale to a value between 0 and 5.

### ContactSensor example:

An ContactSensor can read digital pins of the Arduino and display the
state of it.

```json
{
  "id": "omeduino-contact-sensor",
  "name": "ContactSensor",
  "class": "HomeduinoContactSensor",
  "pin": 9,
  "interval": 1000,
  "inverted": true
}
```
The pin must be set. Interval and inverted are optional.
They are set by default to interval = 10000 and inverted = false.
