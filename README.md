# si70xx-spin 
-------------

This is a P8X32A/Propeller driver object for Silicon Labs Si70xx series temperature/humidity sensors.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

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

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.10-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction or outright fail to build

## TODO

- [x] Read firmware rev
- [x] Read Temp/humidity
- [x] Heater control
- [x] Measurement resolution control
- [ ] Implement optional CRC checking on read data

