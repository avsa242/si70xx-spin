# si70xx-spin 
-------------

This is a P8X32A/Propeller driver object for Silicon Labs Si70xx series temperature/humidity sensors.

## Salient Features

* I2C Connection up to 400kHz
* Reads 64-bit serial number from device
* Reads 8-bit part number from device
* Reads firmware version from device
* Reads temperature in centi-degrees (scale can be set to Fahrenheit or Celsius)
* Reads relative humidity in hundreths of a percent
* Can enable/disable the on-chip heater, and set drive strength/current level
* Can set sensor resolution, in bits

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* Very early in development - may malfunction or outright fail to build

## TODO

- [x] Read firmware rev
- [x] Read Temp/humidity
- [x] Heater control
- [x] Measurement resolution control
- [ ] Implement optional CRC checking on read data

