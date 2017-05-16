--------------------------------------------------------------------------------
--
-- "gameenv-threaded" module
--
-- This module implements the Nintendo Fimicom Mini "game environment",
-- by integrating the "vidcap", "galaga" and "gpio" modules.
--
-- This module tries to do vidcap and galaga parsing work in a separate
-- thread, so as to offload main thread, which could spend more time handling
-- neural network (perceive/train) tasks.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-03-10
--------------------------------------------------------------------------------

require 'torch'

local threads = require 'threads'
local gpio = require 'gpio/gpio'

local gameenv = {}
gameenv.is_initialized = false
gameenv.is_terminated= true
gameenv.thread = nil

local step_state

-- Initialize the game environment.
-- 'game' is the name of the game, default to 'galaga'.
-- 'display_freq' is the frame interval for display, default to 1 frame.
-- Note that display could be disabled by setting display_freq to 0
function gameenv.init(game, display_freq)
    local display_freq = display_freq or 1
    local tensor_type = torch.getdefaulttensortype()

    -- we only support Galaga for now, might expand the list of
    -- supported games later
    gameenv.game = game or 'galaga'
    assert(gameenv.game == 'galaga', gameenv.game .. ' not supported!')

    -- initialize the supporting thread which would be resposible for
    -- capturing video and parsing galaga game images
    gameenv.thread = threads.Threads(1,
        function ()
            require 'image'
            t_vidcap = require 'vidcap/vidcap'
            t_galaga = require 'galaga/galaga'
            t_imshow = require 'imshow/imshow'
            t_disp = display_freq
            t_frames = 0
            t_last_score = 0
            torch.setdefaulttensortype(tensor_type)
        end,
        function ()
            -- init the vidcap module
            t_img = t_vidcap.create_image()
            assert(t_vidcap.init() == 0, 'vidcap.init() failed!')
            if t_disp ~= 0 then
                -- create the display window
                t_imshow.init('nintendo galaga')
            end
        end)

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
    -- reset all gpio pins to known state
    local pins = { 36, 37, 184, 219, 38, 63 }
    for i = 1, #pins do gpio.set_low(pins[i]) end

    -- terminate the supporting thread
    gameenv.thread:addjob(
        function ()
            t_imshow.cleanup()
            t_vidcap.cleanup()
        end)
    gameenv.thread:terminate()

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
-- Note the program busy-waits for this much time without doing useful work.
local function preview_frames(n)
    local ret

    gameenv.thread:addjob(
        function ()
            if n > 1 then t_vidcap.flush() end
            for i = 1, n do
                t_vidcap.get(t_img)
                t_frames = t_frames + 1
                if t_disp ~= 0 and t_frames % t_disp == 0 then
                    t_imshow.display(t_img)
                end
            end
            return { high = t_galaga.has_HIGH(t_img),
                     flag = t_galaga.has_Flag(t_img),
                     lives = t_galaga.get_lives(t_img) }
        end,
        function (t)
            ret = t
        end)
    gameenv.thread:synchronize()
    return ret
end

-- Step 1 frame
local function step_1_frame()
    -- retrieve the returned table (step_state) from the previous job
    gameenv.thread:synchronize()
    -- queue a new job to the supporting thread
    gameenv.thread:addjob(
        function ()
            t_vidcap.get(t_img)
            t_frames = t_frames + 1
            if t_disp ~= 0 and t_frames % t_disp == 0 then
                t_imshow.display(t_img)
            end
            local s = t_galaga.crop_rawstate(t_img):type(torch.getdefaulttensortype()):div(256)  -- normalize pixel values to [0, 1)
            assert(s:size(2) == 336 and s:size(3) == 336)
            s[{ {}, {}, {1, 5} }]:fill(0)
            s[{ {}, {}, {331, 336} }]:fill(0)
            local screen = image.scale(s, 84, 84)
            return { screen = screen,
                     score = t_galaga.get_score(t_img),
                     high = t_galaga.has_HIGH(t_img),
                     result = t_galaga.has_RESULT(t_img) }
        end,
        function (t)
            step_state = t
        end)
    return step_state
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
-- Note the program could busy-wait for a long time, or even forever (if
-- the Nintendo game console is not under Galaga game...)
function gameenv.new_game()
    local start_ok = false
    local t
    gameenv.last_score = 0

    -- wait for the screen with 'HIGH SCORE' but no Flag
    while true do
        t = preview_frames(10)
        if t.high == true and t.flag == false and
           (t.lives == 1 or t.lives == 2) then
            break
        end
    end

    -- try pressing Start button up to 10 times
    -- expect to see a game screen with 3 lives
    for i = 1, 10 do
        start_button(true)
        t = preview_frames(10)
        start_button(false)
        t = preview_frames(10)
        if t.high and t.lives == 3 then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- wait for Flag to appear, up to 10 seconds
    start_ok = false
    for i = 1, 30 do
        t = preview_frames(10)
        if t.flag then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- wait for lives to decrease from 3 to 2, up to 10 seconds
    start_ok = false
    for i = 1, 30 do
        t = preview_frames(10)
        if t.lives == 2 then
            start_ok = true
            break
        end
    end
    assert(start_ok)  -- if timeout then something is wrong

    -- a new game has really started
    gameenv.is_terminated = false

    -- ask the supporting thread to start capturing the 1st video frame
    -- for the new game
    step_1_frame()
end

-- Take one step for the game.
-- 'a' is the action specified by caller. 'a' could be nil, which means
-- no change from previous step.
-- Returns 'screen', 'reward' and 'terminal'.
function gameenv.step(a)
    -- assign a small negative reward as default, to discourage the behavior:
    -- (1) dodging at the corner without trying to take out any enemies,
    -- (2) intentionally colliding with enemies to get some score.
    -- local reward = -0.01
    local reward = 0

    if a then take_action(a) end

    local t = step_1_frame()

    if gameenv.is_terminated then
        return t.screen, 0, true
    end

    -- the following is to work around the problem that galaga.get_score()
    -- might incorrectly return 0 for 1~2 frames around end of a game
    if t.score ~= 0 then
        assert(t.score >= gameenv.last_score)
        if t.score > gameenv.last_score then
            reward = t.score - gameenv.last_score
            gameenv.last_score = t.score
        end
        -- else case: score did not change
    end

    -- check whether the game has ended
    if t.result == true or t.high == false then
        gameenv.is_terminated = true
    end
    return t.screen, reward, gameenv.is_terminated
end

-- Return current score of the game.
-- This is used to evaluate how well the agent has played a game.
function gameenv.get_score()
    return gameenv.last_score
end

return gameenv
