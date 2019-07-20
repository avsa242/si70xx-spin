{
    --------------------------------------------
    Filename: SI7021-Test.spin
    Author: Jesse Burt
    Description: Test of the Si70xx driver
    Copyright (c) 2019
    Started Jul 20, 2019
    Updated Jul 20, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    si7021: "sensor.temp_rh.si7021.i2c"

VAR

    byte _ser_cog

PUB Main | sn[2], i

    Setup
'    long[@sn][0] := $DEADBEEF
'    long[@sn][1] := $C0FFEE11
    bytefill(@sn, 0, 8)
    si7021.SN (@sn)
    repeat i from 7 to 0
        ser.Hex (sn.byte[i], 2)
    ser.NewLine
    ser.Dec ( si7021.PartID)
    Flash (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if si7021.Start
        ser.Str (string("Si7021 driver started", ser#NL, ser#LF))
    else
        ser.Str (string("Si7021 driver failed to start - halting", ser#NL, ser#LF))
        si7021.Stop
        time.MSleep (500)
        ser.Stop

PUB Flash(pin, delay_ms)

    dira[pin] := 1
    repeat
        !outa[pin]
        time.MSleep (delay_ms)



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
