--------------------------------------------------------------------------------
--
-- "gpio" module
--
-- This module implements GPIO output functions through FFI. The underlying
-- C code uses /sys/class/gpio interface to access GPIO.
--
-- Note the following gpio pins are available on J21 of Jetson TX1:
-- 36, 37, 38, 63, 184, 186, 187, 219
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-16
--------------------------------------------------------------------------------

local ffi = require 'ffi'
local gpio = {}
local lib = ffi.load(paths.cwd() .. '/gpio/libgpio.so')

-- Function prototype definition
ffi.cdef [[
    void gpio_export(int pin);
    void gpio_unexport(int pin);
    void gpio_set_output(int pin);
    void gpio_set_high(int pin);
    void gpio_set_low(int pin);
]]

function gpio.export(p)     lib.gpio_export(p)     end
function gpio.unexport(p)   lib.gpio_unexport(p)   end
function gpio.set_output(p) lib.gpio_set_output(p) end
function gpio.set_high(p)   lib.gpio_set_high(p)   end
function gpio.set_low(p)    lib.gpio_set_low(p)    end

return gpio
