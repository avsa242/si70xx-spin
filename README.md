# si70xx-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Silicon Labs Si70xx series temperature/humidity sensors.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C Connection up to 400kHz
* Temperature in hundredths of a degree (scale can be set to Fahrenheit or Celsius)
* Relative humidity in hundredths of a percent
* On-chip heater control: enable/disable, set drive strength/current level
* Set sensor resolution, in bits
* Read chip-specific info: device ID/part number, firmware rev, 64-bit serial number

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 5.3.3-beta)
* P2/SPIN2: FlexSpin (tested with 5.3.3-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction or outright fail to build

## TODO

- [x] Port to P2/SPIN2
- [x] Read firmware rev
- [x] Read Temp/humidity
- [x] Heater control
- [x] Measurement resolution control
- [ ] Implement optional CRC checking on read data

