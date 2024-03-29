{
    --------------------------------------------
    Filename: sensor.temp_rh.si70xx.spin
    Author: Jesse Burt
    Description: Driver for Silicon Labs Si70xx-series temperature/humidity sensors
    Copyright (c) 2022
    Started Jul 20, 2019
    Updated Dec 28, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{ pull in methods common to all Temp/RH drivers }
#include "sensor.temp_rh.common.spinh"

CON

    { I2C }
    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR | 1
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef SI70XX_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.si70xx"                     ' HW-specific constants
    time: "time"                                ' timekeeping methods
    crc : "math.crc"                            ' various CRC routines

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            if (i2c.present(SLAVE_WR))          ' check device bus presence
                reset{}
                if (lookdown(dev_id{}: $0D, $14, $15, $00, $FF))
                    return

    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB dev_id{}: id | tmp[2]
' Read the Part number portion of the serial number
'   Returns:
'       $00/$FF: Engineering samples
'       $0D (13): Si7013
'       $14 (20): Si7020
'       $15 (21): Si7021
    serial_num(@tmp)
    return tmp.byte[3]

PUB firmware_rev{}: fwrev
' Read sensor internal firmware revision
'   Returns:
'       $FF: Version 1.0
'       $20: Version 2.0
    readreg(core#RD_FIRMWARE_REV, 1, @fwrev)

PUB heater_curr{}: curr
' Get heater current
'   Returns: milliamperes
'   NOTE: Values are approximate, and typical
    curr := 0
    readreg(core#RD_HEATER, 1, @curr)
    curr &= core#HEATER_BITS
    return lookupz(curr: 3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94)

PUB heater_set_curr(curr)
' Set heater current, in milliamperes
'   Valid values: *3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94 (clamped to range)
'   NOTE: Values are approximate, and typical
    curr := 0 #> lookdownz(curr: 3, 9, 15, 21, 27, 33, 40, 46, 52, 58, 64, 70, 76, 82, 88, 94)
    writereg(core#WR_HEATER, 1, @curr)

PUB heater_ena(state): curr_state
' Enable the on-chip heater
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#RD_RH_T_USER1, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#HTRE
        other:
            return ((curr_state >> core#HTRE) & 1) == 1

    state := ((curr_state & core#HTRE_MASK) | state) & core#RD_RH_T_USER1_MASK
    writereg(core#WR_RH_T_USER1, 1, @state)

PUB measure{}
' dummy method

PUB reset{}
' Perform soft-reset
    writereg(core#RESET, 0, 0)
    time.msleep(15)

PUB rh_adc_res(bits): curr_res
' Set resolution of RH readings, in bits
'   Valid values:
'       8, 10, 11, 12
'   Any other value polls the chip and returns the current setting
'   NOTE: Setting this method directly affects temperature ADC resolution also
'   The following table shows equivalent settings for temperature:
'       RH  Temp
'       8   12
'       10  13
'       11  11
'       12  14
    curr_res := 0
    readreg(core#RD_RH_T_USER1, 1, @curr_res)
    case bits
        8, 10, 11, 12:
            bits := lookdownz(bits: 12, 8, 10, 11)
            bits := lookupz(bits: $00, $01, $80, $81)
        other:
            curr_res &= core#ADCRES_BITS
            curr_res := lookdownz(curr_res: $00, $01, $80, $81)
            return lookupz(curr_res: 12, 8, 10, 11)

    bits := (curr_res & core#ADCRES_MASK) | bits
    writereg(core#WR_RH_T_USER1, 1, @bits)

PUB rh_data{}: rh_adc
' Read relative humidity ADC data
'   Returns: u16
    rh_adc := 0
    readreg(core#MEAS_RH_NOHOLD, 2, @rh_adc)

PUB rh_word2pct(rh_word): rh
' Convert RH ADC word to percent
'   Returns: relative humidity, in hundredths of a percent
    return ((125_00 * rh_word) / 65536) - 6_00

PUB serial_num(ptr_buff): status | snb, sna
' Read the 64-bit serial number of the device into ptr_buff
'   NOTE: Buffer at ptr_buff must be at least 8 bytes in length
'   Returns: 0 on success, -1 on failure
    status := 0
    longfill(@sna, 0, 2)
    if (readreg(core#RD_SERIALNUM_1, 4, @sna) == -1)
        return -1
    if (readreg(core#RD_SERIALNUM_2, 4, @snb) == -1)
        return -1
    longmove(ptr_buff, @snb, 2)

PUB temp_adc_res(bits): curr_res
' Set resolution of temperature readings, in bits
'   Valid values:
'       11, 12, 13, 14
'   Any other value polls the chip and returns the current setting
'   NOTE: Setting this method directly affects RH ADC resolution also
'   The following table shows equivalent settings for RH:
'       Temp    RH
'       11      11
'       12      8
'       13      10
'       14      12
    curr_res := 0
    readreg(core#RD_RH_T_USER1, 1, @curr_res)
    case bits
        11..14:
            bits := lookdownz(bits: 14, 12, 13, 11)
            bits := lookupz(bits: $00, $01, $80, $81)
        other:
            curr_res &= core#ADCRES_BITS
            curr_res := lookdownz(curr_res: $00, $01, $80, $81)
            return lookupz(curr_res: 12, 8, 10, 11)

    bits := (curr_res & core#ADCRES_MASK) | bits
    writereg(core#WR_RH_T_USER1, 1, @bits)

PUB temp_data{}: temp_adc
' Read temperature ADC data
'   Returns: s16
    temp_adc := 0
    readreg(core#READ_PREV_TEMP, 2, @temp_adc)

PUB temp_word2deg(temp_word): temp
' Convert thermocouple ADC word to temperature
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp := ((175_72 * temp_word) / 65536) - 46_85
    case _temp_scale
        C:
            return temp
        F:
            return ((temp * 9) / 5) + 32_00
        other:
            return FALSE

PRI readreg(reg_nr, nr_bytes, ptr_buff): status | cmd_pkt, tmp, crcrd, rdcnt
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr
        core#READ_PREV_TEMP:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wait(SLAVE_RD)
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        core#MEAS_RH_NOHOLD:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wait(SLAVE_RD)
            tmp := i2c.rdword_msbf(i2c#ACK)
            crcrd := i2c.rd_byte(i2c#NAK)
            i2c.stop{}
            if (crcrd == crc.silabs_crc8(@tmp, 2))
                word[ptr_buff] := tmp
            else
                return -1
        core#MEAS_TEMP_HOLD:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.start{}
            i2c.write(SLAVE_RD)
            time.msleep(11)
            tmp := i2c.rdword_msbf(i2c#ACK)
            crcrd := i2c.rd_byte(i2c#NAK)
            i2c.stop{}
            if (crcrd == crc.silabs_crc8(@tmp, 2))
                word[ptr_buff] := tmp
            else
                return -1
        core#MEAS_TEMP_NOHOLD:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wait(SLAVE_RD)
            tmp := i2c.rdword_msbf(i2c#ACK)
            crcrd := i2c.rd_byte(i2c#NAK)
            i2c.stop{}
            if (crcrd == crc.silabs_crc8(@tmp, 2))
                word[ptr_buff] := tmp
            else
                return -1
        core#RD_RH_T_USER1, core#RD_HEATER:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wait(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        core#RD_SERIALNUM_1:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)
            ' reference:
            ' https://community.silabs.com/s/question/0D51M00007xeGA9/how-to-calculate-crc-in-si7021?language=en_US
            ' ...for the following quirky behavior - how the CRC is calculated
            '   doesn't quite match the datasheet p.23
            ' Instead of verifying each SN byte with its own CRC byte, as the
            '   diagram in the datasheet seems to imply, the crc should be
            '   calculated over the entire 4-byte sequence, and compared with
            '   the very last CRC byte received. All prior CRC bytes are
            '   ignored.
            rdcnt := 1
            tmp := 0
            repeat 2
                tmp.byte[(rdcnt*2)+1] := i2c.rd_byte(i2c#ACK)
                i2c.rd_byte(i2c#ACK)            ' ignore the 1st CRC byte
                tmp.byte[rdcnt*2] := i2c.rd_byte(i2c#ACK)
                crcrd := i2c.rd_byte(rdcnt-- == 0)
            if (crc.silabs_crc8(@tmp, 4) == crcrd)
                long[ptr_buff] := tmp
                status := 0
            else
                status := -1
            return status
        core#RD_SERIALNUM_2:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)
            rdcnt := 1
            repeat 2
                tmp.word[rdcnt] := i2c.rdword_msbf(i2c#ACK)
                crcrd := i2c.rd_byte(rdcnt-- == 0)
            if (crcrd == crc.silabs_crc8(@tmp, 4))
                long[ptr_buff] := tmp
            else
                status := -1
            i2c.stop{}
            return
        core#RD_FIRMWARE_REV:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.wait(SLAVE_RD)
            byte[ptr_buff] := i2c.rd_byte(i2c#NAK)
            i2c.stop{} 
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to the slave device
    case reg_nr
        core#RESET:
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(reg_nr)
            i2c.stop{}
        core#WR_RH_T_USER1, core#WR_HEATER:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            cmd_pkt.byte[2] := byte[ptr_buff][0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}
        other:
            return

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

