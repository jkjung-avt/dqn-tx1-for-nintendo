--------------------------------------------------------------------------------
--
-- "gameenv" module
--
-- This module implements the Nintendo Fimicom Mini "game environment",
-- by integrating the "vidcap", "galaga" and "gpio" modules.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-24
--------------------------------------------------------------------------------

require 'torch'
require 'image'

local gameenv = {}
gameenv.is_initialized = false
gameenv.is_terminated= true
gameenv.win = nil

local vidcap = require 'vidcap/vidcap'
local galaga = require 'galaga/galaga'
local gpio   = require 'gpio/gpio'

-- Initialize the game environment.
-- 'game' is the name of the game, default to 'galaga'.
-- 'display_freq' is the frame interval for display, default to 3 frames.
-- Note that display could be disabled by setting display_freq to 0
function gameenv.init(game, display_freq)
    gameenv.game = game or 'galaga'
    gameenv.display_freq = display_freq or 3
    gameenv.cnt = 0  -- frame count
    gameenv.last_score = 0

    -- we only support Galaga for now, might expand the list of
    -- supported games later
    assert(gameenv.game == 'galaga', 'Game ' .. gameenv.game .. ' not supported!')

    -- init the vidcap module
    gameenv.img = vidcap.create_image()
    gameenv.img:fill(0)
    local ret = vidcap.init()
    assert(ret == 0, 'vidcap.init() failed!')

    if gameenv.display_freq ~= 0 then
        -- create the display window (all 0's = black screen)
        gameenv.win = image.display({image = gameenv.img, legend = 'nintendo ' .. gameenv.game, win = gameenv.win})
    end

    -- init gpio pins
    local pins = { 36, 37, 184, 219, 38, 63 }
    for i = 1, #pins do gpio.export(pins[i]) end
    os.execute('sleep 1')  -- sleep 1 sec to make sure udev rules take effect
    for i = 1, #pins do gpio.set_output(pins[i]) end
    for i = 1, #pins do gpio.set_low(pins[i]) end

    gameenv.is_initialized = true
end

-- Clean up the game environment.
function gameenv.cleanup()
    local pins = { 36, 37, 184, 219, 38, 63 }
    for i = 1, #pins do gpio.set_low(pins[i]) end
    vidcap.cleanup()
    gameenv.is_initialized = false
end

-- Get the list of available actions.
-- get_actions() is now hard-coded for Galaga...
function gameenv.get_actions()
    assert(gameenv.is_initialized, 'get_action() called while gameenv is not initialized')
    local actions = { 1, 2, 3, 4, 5, 6 }
    -- Six possible actions are defined for Galaga:
    -- 1 = Left
    -- 2 = Stay
    -- 3 = Right
    -- 4 = Left  + Fire
    -- 5 = Stay  + Fire
    -- 6 = Right + Fire
    return actions
end

-- Press or release 'Start' button of the Nintendo game console.
-- This is used to restart a new game.
local function start_button(press)
    -- Start button is controlled by gpio63
    if press then
        gpio.set_high(63)
    else
        gpio.set_low(63)
    end
end

-- Preview (without doing any action) the specified number of frames.
-- It's assumed the game video is rendered at 30 fps.
-- Note the program would block for this much time without doing useful work.
local function preview_frames(n)
    for i = 1, n do
        vidcap.get(gameenv.img)
        gameenv.cnt = gameenv.cnt + 1
        if gameenv.display_freq ~= 0 and
           gameenv.cnt % gameenv.display_freq == 0 then
            gameenv.win = image.display({image = gameenv.img, legend = 'nintendo ' .. gameenv.game, win = gameenv.win})
        end
    end
end

-- Take an action.
-- 'a' is the action specified by caller: 1~6 are valid actions for Galaga,
-- while 0 is a special case used to indicate no-op (release all buttons).
-- take_actions() is now hard-coded for Galaga...
-- 1~6
local function take_action(a)
    -- set all gpio pins to low (release all buttons)
    local pins = { 36, 37, 184, 219, 38, 63 }
    for i = 1, #pins do gpio.set_low(pins[i]) end

    --   GPIO pin #    Nintendo button
    --      36             Left
    --      37             Right
    --      38             A (Fire)

    -- set corresponding gpio pin(s) to high (press certain buttons)
    if a == 1 then gpio.set_high(36) end                    -- Left
    if a == 3 then gpio.set_high(37) end                    -- Right
    if a == 5 then gpio.set_high(38) end                    -- Fire
    if a == 4 then gpio.set_high(36) gpio.set_high(38) end  -- L + F
    if a == 6 then gpio.set_high(37) gpio.set_high(38) end  -- R + F
end

-- Discard current game, and try to start a new game.
-- new_game() is hard-coded for Galaga...
-- Note the program could block for a long time, or even forever (if the
-- Nintendo game console is not under Galaga game...)
function gameenv.new_game()
    local start_ok = false
    local img = gameenv.img
    gameenv.last_score = 0
    vidcap.flush()

    -- wait for the screen with 'HIGH SCORE' but no Flag
    while true do
        preview_frames(10)
        if galaga.has_HIGH(img) and not galaga.has_Flag(img) then
            local lives = galaga.get_lives(img)
            if lives == 1 or lives == 2 then break end
        end
    end

    -- try pressing Start button up to 10 times
    -- expect to see a game screen with 3 lives
    for i = 1, 10 do
        start_button(true)
        preview_frames(10)
        start_button(false)
        preview_frames(10)
        if galaga.has_HIGH(img) and galaga.get_lives(img) == 3 then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- wait for Flag to appear, up to 10 seconds
    start_ok = false
    for i = 1, 30 do
        preview_frames(10)
        if galaga.has_Flag(img) then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- wait for lives to decrease from 3 to 2, up to 10 seconds
    start_ok = false
    for i = 1, 30 do
        preview_frames(10)
        if galaga.get_lives(img) == 2 then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- a new game has really started
    gameenv.is_terminated = false
end

-- Take one step for the game.
-- 'a' is the action specified by caller. 'a' could be nil, which means
-- no change from previous step.
-- Returns 'screen', 'reward' and 'terminal'.
function gameenv.step(a)
    -- assign a small negative reward as default, to discourage the behavior:
    -- (1) dodging at the corner without trying to take out any enemies,
    -- (2) intentionally colliding with enemies to get some score.
    local reward = -0.01

    if a then take_action(a) end
    preview_frames(1)
    local img = gameenv.img
    local screen = galaga.crop_rawstate(img):type(torch.getdefaulttensortype()):div(256)  -- normalize pixel values to [0, 1)

    if gameenv.is_terminated then
        return screen, 0, true
    end

    local score = galaga.get_score(img)
    -- the following is to work around the problem that galaga.get_score()
    -- might incorrectly return 0 for 1~2 frames around end of a game
    if score ~= 0 then
        assert(score >= gameenv.last_score)
        if score > gameenv.last_score then
            reward = score - gameenv.last_score
            gameenv.last_score = score
        end
        -- else case: score did not change
    end

    -- check whether the game has ended
    if galaga.has_RESULT(img) or not galaga.has_HIGH(img) then
        gameenv.is_terminated = true
    end
    return screen, reward, gameenv.is_terminated
end

-- Return current score of the game.
-- This is used to evaluate how well the agent has played a game.
function gameenv.get_score()
    return gameenv.last_score
end

return gameenv
