--------------------------------------------------------------------------------
--
-- Test code of "gpio" module
--
-- This script is used to generate joystick control signal to Nintendo
-- Famicom Mini. It should be run from the top directory:
-- 
--   $ qlua test/test_joystick.lua
--
-- Note that I've wired TX1 GPIO to Nintendo joystick according the table
-- below. In addition, I've also mapped caertain keyboard keys to control
-- these GPIO pins.
--
--   GPIO pin #    Nintendo button    Keyboard key
--      36             Left            'A' or 'a'
--      37             Right           'D' or 'd'
--      184            Up              'W' or 'w'
--      219            Down            'S' or 's'
--      38             A (Fire)        SPACE
--      63             Start           ENTER
--      
-- The test script quits when the user hits ESC key.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-16
--------------------------------------------------------------------------------

gpio = require 'gpio/gpio'
term = require 'term/term'

term.init()

pins = { 36, 37, 184, 219, 38, 63 }
key_to_gpio = {
    [65]  = 36,   -- 'A'   = Left
    [97]  = 36,   -- 'a'   = Left
    [68]  = 37,   -- 'D'   = Right
    [100] = 37,   -- 'D'   = Right
    [87]  = 184,  -- 'W'   = Up
    [119] = 184,  -- 'w'   = Up
    [83]  = 219,  -- 'S'   = Down
    [115] = 219,  -- 's'   = Down
    [32]  = 38,   -- SPACE = A (Fire)
    [10]  = 63,   -- ENTER = Start
}

for i = 1, #pins do gpio.export(pins[i]) end
os.execute('sleep 1')  -- sleep 1 sec to make sure udev rules take effect
for i = 1, #pins do gpio.set_output(pins[i]) end
for i = 1, #pins do gpio.set_low(pins[i]) end

while true do
    local c = term.waitkey(30)
    if c then
        if c == string.byte('.') then break end
        local p = key_to_gpio[c]
        if p then
            gpio.set_high(p)
            term.msleep(30)
            print('key ' .. c .. ' ->', 'gpio'..p)
        end
    else
        for i = 1, #pins do gpio.set_low(pins[i]) end
    end
end

term.cleanup()

for i = 1, #pins do gpio.set_low(pins[i]) end
for i = 1, #pins do gpio.unexport(pins[i]) end
