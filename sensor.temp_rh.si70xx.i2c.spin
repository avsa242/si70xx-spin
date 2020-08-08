{
    --------------------------------------------
    Filename: sensor.temp_rh.si70xx.i2c.spin
    Author: Jesse Burt
    Description: Driver for Silicon Labs Si70xx-series temperature/humidity sensors
    Copyright (c) 2020
    Started Jul 20, 2019
    Updated Aug 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

    SCALE_C = 0
    SCALE_F = 1

VAR

    byte _temp_scale

OBJ

    i2c : "com.i2c"                                             'PASM I2C Driver
    core: "core.con.si70xx.spin"                           'File containing your device's register set
    time: "time"                                                'Basic timing functions
    crc : "math.crc"

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (core#TPU)                          ' Wait tPU ms for startup
                if i2c.present (SLAVE_WR)                       'Response from device?
                    Reset
                    if lookdown(deviceid{}: $0D, $14, $15, $00, $FF)
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB ADCRes(bits) | tmp
' Set resolution of readings, in bits
'   Valid values:
'                   RH  Temp
'      *12_14:      12  14 bits
'       8_12:       8   12
'       10_13:      10  13
'       11_11:      11  11
'   Any other value polls the chip and returns the current setting
'   NOTE: The underscore in the setting isn't necessary - it only serves as a visual aid to separate the two fields
    tmp := 0
    readReg(core#RD_RH_T_USER1, 1, @tmp)
    case bits
        12_14, 8_12, 10_13, 11_11:
            bits := lookdownz(bits: 12_14, 8_12, 10_13, 11_11)
            bits := lookupz(bits: $00, $01, $80, $81)

        OTHER:
            result := tmp & core#BITS_RES
            result := lookdownz(result: $00, $01, $80, $81)
            return lookupz(result: 12_14, 8_12, 10_13, 11_11)

    tmp &= core#MASK_RES
    tmp := (tmp | bits)
    writeReg(core#WR_RH_T_USER1, 1, @tmp)

PUB DeviceID{} | tmp[2]
' Read the Part number portion of the serial number
'   Returns:
'       $00/$FF: Engineering samples
'       $0D (13): Si7013
'       $14 (20): Si7020
'       $15 (21): Si7021
    SerialNum(@tmp)
    return tmp.byte[4]

PUB FirmwareRev
' Read sensor internal firmware revision
'   Returns:
'       $FF: Version 1.0
'       $20: Version 2.0
    readReg(core#RD_FIRMWARE_REV, 1, @result)

PUB Heater(enabled) | tmp
' Enable the on-chip heater
'   Valid values: TRUE (-1 or 1), *FALSE (0)
    readReg(core#RD_RH_T_USER1, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_HTRE
        OTHER:
            result := tmp >> core#FLD_HTRE
            return (result & %1) * TRUE

    tmp &= core#MASK_HTRE
    tmp := (tmp | enabled) & core#RD_RH_T_USER1
    tmp := enabled
    writeReg(core#WR_RH_T_USER1, 1, @tmp)

PUB HeaterCurrent(mA) | tmp
' Set heater current, in milliamperes
'   Valid values: *3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94
'   Any other value polls the chip and returns the current setting
'   NOTE: Values are approximate, and typical
    readReg(core#RD_HEATER, 1, @tmp)
    case mA
        3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94:
            mA := lookdownz(mA: 3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94)
        OTHER:
            tmp &= core#BITS_HEATER
            return lookupz(tmp: 3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94)

    mA &= core#BITS_HEATER
    writeReg(core#WR_HEATER, 1, @mA)

PUB Humidity | tmp
' Read humidity
'   Returns: Relative Humidity, in hundreths of a percent
    tmp := result := 0
    readReg(core#MEAS_RH_NOHOLD, 2, @result)
'    if result.byte[3] == 1
'        return $E000_000C
    result := ((125_00 * result) / 65536) - 6_00
    return result

PUB Reset
' Perform soft-reset
    writeReg(core#RESET, 0, 0)
    time.MSleep (15)

PUB Scale(temp_scale)
' Set scale of temperature data returned by Temperature method
'   Valid values:
'      *SCALE_C (0): Celsius
'       SCALE_F (1): Fahrenheit
'   Any other value returns the current setting
    case temp_scale
        SCALE_F, SCALE_C:
            _temp_scale := temp_scale
            return _temp_scale
        OTHER:
            return _temp_scale

PUB SerialNum(buff_addr) | sna[2], snb[2]
' Read the 64-bit serial number of the device
    longfill(@sna, 0, 4)
    readReg(core#RD_SERIALNUM_1, 8, @sna)
    readReg(core#RD_SERIALNUM_2, 6, @snb)
    byte[buff_addr][0] := sna.byte[0]
    byte[buff_addr][1] := sna.byte[2]
    byte[buff_addr][2] := sna.byte[4]
    byte[buff_addr][3] := sna.byte[6]
    byte[buff_addr][4] := snb.byte[0]
    byte[buff_addr][5] := snb.byte[1]
    byte[buff_addr][6] := snb.byte[3]
    byte[buff_addr][7] := snb.byte[4]

PUB Temperature | tmp
' Read temperature
'   Returns: Temperature, in centidegrees Celsius
    tmp := result := 0
    readReg(core#READ_PREV_TEMP, 2, @result)
    result := ((175_72 * result) / 65536) - 46_85
    case _temp_scale
        SCALE_F:
            if result > 0
                result := result * 9 / 5 + 32_00
            else
                result := 32_00 - (||result * 9 / 5)
        OTHER:
            return result

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp, crc_in, rt
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg
        core#READ_PREV_TEMP:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 2)
            i2c.Wait (SLAVE_RD)
            repeat tmp from nr_bytes-1 to 0
                if tmp > 0
                    byte[buff_addr][tmp] := i2c.Read (FALSE)
                else
                    byte[buff_addr][tmp] := i2c.Read (TRUE)
            i2c.Stop

        core#MEAS_RH_NOHOLD:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 2)
            i2c.Wait (SLAVE_RD)
            repeat tmp from nr_bytes-1 to 0' to nr_bytes-1' to 0
'                rt.byte[tmp] := i2c.Read (FALSE)
                if tmp > 0
                    byte[buff_addr][tmp] := i2c.Read (FALSE)
                else
                    byte[buff_addr][tmp] := i2c.Read (TRUE)
            crc_in := i2c.Read (TRUE)
'            if crc_in == crc.SiLabsCRC8 (buff_addr, 2)'data, len)
'                byte[buff_addr][3] := 1
            i2c.Stop

        core#MEAS_TEMP_HOLD:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 2)
            i2c.Start
            i2c.Write (SLAVE_RD)
            time.MSleep (11)
            repeat tmp from nr_bytes-1 to 0
                if tmp > 0
                    byte[buff_addr][tmp] := i2c.Read (FALSE)
                else
                    byte[buff_addr][tmp] := i2c.Read (TRUE)
            i2c.Stop

        core#MEAS_TEMP_NOHOLD:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 2)
            i2c.Wait (SLAVE_RD)
            repeat tmp from nr_bytes-1 to 0
                if tmp > 0
                    byte[buff_addr][tmp] := i2c.Read (FALSE)
                else
                    byte[buff_addr][tmp] := i2c.Read (TRUE)
            i2c.Stop

        core#RD_RH_T_USER1, core#RD_HEATER:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 2)
            i2c.Wait (SLAVE_RD)
            i2c.Rd_Block (buff_addr, nr_bytes, TRUE)
            i2c.Stop

        core#RD_SERIALNUM_1, core#RD_SERIALNUM_2, core#RD_FIRMWARE_REV:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Wait (SLAVE_RD)
            i2c.Rd_Block (buff_addr, nr_bytes, FALSE)
            i2c.Stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        core#RESET:
            i2c.Start
            i2c.Write (SLAVE_WR)
            i2c.Write (reg)
            i2c.Stop
        core#WR_RH_T_USER1, core#WR_HEATER:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            cmd_packet.byte[2] := byte[buff_addr][0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Stop
        OTHER:
            return


DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
