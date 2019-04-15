# Release History

* 20190415, V0.9.12
    * Added xUpLabel, xDownLabel, xStoppedLabel extensions to HomeduinoRFShutter, issue #70
    * Only listen to "on" event on switch discovery to prevent invalid device 
      types, thanks @Wiebe Nieuwenhuis
    * Validity check on temperature and/or humidity to prevent invalid devices on 
      discovery, thanks @Wiebe Nieuwenhuis
    * Added battery indicator support for HomeduinoRFContactSensor
    * Added option "inverted" for HomeduinoRFContactSensor, thanks @Bernd Strebel
    * Added HomeduinoRFShutter rollingTime attribute to support moving shutter 
      by percentage, thanks @Michael Kotten
    * Updated to homeduino@0.0.67 which includes migration to serialport@6 for
      supporting newer Node.js version
