{
    --------------------------------------------
    Filename: sensor.temp_rh.si7021.i2c.spin
    Author: Jesse Burt
    Description: Driver for Silicon Labs Si70xx-series temperature/humidity sensors
    Copyright (c) 2019
    Started Jul 20, 2019
    Updated Jul 20, 2019
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

VAR


OBJ

    i2c : "com.i2c"                                             'PASM I2C Driver
    core: "core.con.si7021.spin"                           'File containing your device's register set
    time: "time"                                                'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (80)
                if i2c.present (SLAVE_WR)                       'Response from device?
                    return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB FirmwareRev
' Read sensor internal firmware revision
'   Returns:
'       $FF: Version 1.0
'       $20: Version 2.0
    readReg( core#RD_FIRMWARE_REV, 1, @result)

PUB PartID | tmp[2]
' Read the Part number portion of the serial number
'   Returns:
'       $00/$FF: Engineering samples
'       $0D (13): Si7013
'       $14 (20): Si7020
'       $15 (21): Si7021
    SN(@tmp)
    return tmp.byte[3]

PUB SN(buff_addr) | sna[2], snb[2]
' Read the 64-bit serial number of the device
    longfill(@sna, 0, 2)
    longfill(@sna, 0, 2)
    readReg(core#RD_SERIALNUM_1, 1, @sna)
    readReg(core#RD_SERIALNUM_2, 1, @snb)
    byte[buff_addr][0] := snb.byte[4]
    byte[buff_addr][1] := snb.byte[3]
    byte[buff_addr][2] := snb.byte[1]
    byte[buff_addr][3] := snb.byte[0]
    byte[buff_addr][4] := sna.byte[6]
    byte[buff_addr][5] := sna.byte[4]
    byte[buff_addr][6] := sna.byte[2]
    byte[buff_addr][7] := sna.byte[0]


PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    cmd_packet.byte[0] := SLAVE_WR
    case reg                                                    'Basic register validation
        $00..$FF:                                               ' Consult your device's datasheet!
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            i2c.start
            i2c.write (SLAVE_RD)
            i2c.rd_block (buff_addr, nr_bytes, TRUE)
            i2c.stop
        core#RD_SERIALNUM_1:
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Start
            i2c.Write (SLAVE_RD)
            i2c.Rd_Block (buff_addr, 8, FALSE)
            i2c.Stop
        core#RD_SERIALNUM_2:
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Start
            i2c.Write (SLAVE_RD)
            i2c.Rd_Block (buff_addr, 6, FALSE)
            i2c.Stop
        core#RD_FIRMWARE_REV:
            cmd_packet.byte[1] := reg.byte[1]
            cmd_packet.byte[2] := reg.byte[0]
            i2c.Start
            i2c.Wr_Block (@cmd_packet, 3)
            i2c.Start
            i2c.Write (SLAVE_RD)
            i2c.Rd_Block (buff_addr, 1, FALSE)
            i2c.Stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        $00..$FF:                                               ' Consult your device's datasheet!
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])
            i2c.stop
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
