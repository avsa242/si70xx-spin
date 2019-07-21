{
    --------------------------------------------
    Filename: SI7021-Test.spin
    Author: Jesse Burt
    Description: Test of the Si70xx driver
    Copyright (c) 2019
    Started Jul 20, 2019
    Updated Jul 21, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    si7021  : "sensor.temp_rh.si7021.i2c"
    int     : "string.integer"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    byte _ser_cog, _temp_scale

PUB Main | sn[2], i, temp

    Setup
    bytefill(@sn, 0, 8)
    si7021.SN (@sn)
    ser.Str (string("Serial number: "))
    repeat i from 7 to 0
        ser.Hex (sn.byte[i], 2)
    ser.NewLine

    ser.Str (string("Part ID: "))
    ser.Dec (si7021.PartID)
    ser.NewLine

    ser.Str (string("Firmware rev: "))
    ser.Hex (si7021.FirmwareRev, 2)

    si7021.Reset
    _temp_scale := si7021.Scale (si7021#SCALE_C)
    fs.SetPrecision (5)

        ser.Position (0, 6)
        temp := si7021.Humidity
        ser.Dec (Temp)
        time.MSleep (100)

    repeat
{' Display measurements using floating-point math
        ReadTemp_Float
        ReadRH_Float
}

' Display measurements using fixed-point math
        ReadTemp_Int
        ReadRH_Int
        time.MSleep (100)

PUB ReadRH_Float | rh

    rh := si7021.Humidity
    rh := math.FFloat (rh)
    rh := math.FDiv (rh, 100.0)
    ser.Position (0, 7)
    ser.Str (string("Humidity: "))
    ser.Str(fs.FloatToString (rh))
    ser.Char ("%")
    ser.Chars (32, 10)

PUB ReadRH_Int | rh

    rh := si7021.Humidity
    ser.Position (0, 7)
    ser.Str (string("Humidity: "))
    DispDec (rh)
    ser.Char ("%")

PUB ReadTemp_Float | temp

    temp := si7021.Temperature
    temp := math.FFloat (temp)
    temp := math.FDiv (temp, 100.0)
    ser.Position (0, 6)
    ser.Str (string("Temperature: "))
    ser.Str(fs.FloatToString (temp))
    ser.Char (lookupz(_temp_scale: "C", "F"))
    ser.Chars (32, 10)

PUB ReadTemp_Int | temp

    temp := si7021.Temperature
    ser.Position (0, 6)
    ser.Str (string("Temperature: "))
    DispDec (temp)
    ser.Char (lookupz(_temp_scale: "C", "F"))

PUB DispDec(centi_meas) | temp

    ser.Str(int.DecPadded(centi_meas/100, 3))
    ser.Char(".")
    ser.Str(int.DecZeroed(centi_meas//100, 2))
    ser.Char (ser#CE)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if si7021.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
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
