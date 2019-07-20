# si7021-spin 
---------------

This is a P8X32A/Propeller driver object for Silicon Labs Si70xx series temperature/humidity sensors.

## Salient Features

* I2C Connection up to 400kHz
* Reads 64-bit serial number from device
* Reads 8-bit part number from device

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* Very early in development - may malfunction or outright fail to build

## TODO

- [ ] Read firmware rev
- [ ] Read Temp/humidity
- [ ] Heater control
- [ ] Measurement resolution control
- [ ] Implement optional CRC checking on read data

