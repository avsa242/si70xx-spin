{
    --------------------------------------------
    Filename: core.con.si7021.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Jul 20, 2019
    Updated Jul 20, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 400_000
    SLAVE_ADDR          = $40 << 1
    TPU                 = 80    'Powerup time

' Register definitions

    MEAS_RH_HOLD        = $E5
    MEAS_RH_NOHOLD      = $F5
    MEAS_TEMP_HOLD      = $E3
    MEAS_TEMP_NOHOLD    = $F3
    READ_PREV_TEMP      = $E0
    RESET               = $FE
    WR_RH_T_USER1       = $E6
    RD_RH_T_USER1       = $E7
    WR_HEATER           = $51
    RD_HEATER           = $11
    RD_SERIALNUM_1      = $FA0F
    RD_SERIALNUM_2      = $FCC9
    RD_FIRMWARE_REV     = $84B8



PUB Null
'' This is not a top-level object
