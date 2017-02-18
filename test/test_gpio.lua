--------------------------------------------------------------------------------
--
-- Test code of "gpio" module
--
-- This should be run from the top directory:
-- 
--   $ qlua test/test_gpio.lua
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-16
--------------------------------------------------------------------------------

require 'torch'

gpio = require 'gpio/gpio'
pin = 38  -- use gpio38 for testing

function sleep(n)
    os.execute("sleep " .. tonumber(n))
end

gpio.export(pin)
sleep(1)  -- sleep 1 second to make sure udev rules take effect
gpio.set_output(pin)

for i = 1, 3 do
    gpio.set_high(pin)
    io.write('+')
    io.flush()
    sleep(1)
    gpio.set_low(pin)
    io.write('-')
    io.flush()
    sleep(1)
end
io.write('\n')

gpio.unexport(pin)
