--------------------------------------------------------------------------------
--
-- "galaga" module
--
-- This module is used to determine game states of the "Galaga" game on
-- Nintendo Famicom Mini. Game states include whether the game is in action
-- (or game over), current score (reward for the AI agent) of the game, and
-- maybe also how many lives are remaining.
--
-- The caller is responsible for providing game images to this module.
--
-- All images and rectangles in this module are assumed with dimension
-- (C,H,W), which C stands for number of color channels, H for height and
--  W for width.
--
-- I explicitly use torch.DoubleTensor for calculation since it seems to
-- run faster on CPU (comparing to torch.FloatTensor) this way.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-10
--------------------------------------------------------------------------------

require 'torch'

local galaga = {}
local galaga_image = torch.load('galaga/galaga_image.t7')

-- Check whether there is some image (>20% pixels with value greater than
-- or equal to 16) in the rectangle. Returns true or false.
local function is_icon_present(rect, percentage)
    -- threshold at 16, and only compare the 1st channel of rect
    local y = rect[1]
    local active_ratio = y[y:ge(16)]:numel() / y:numel()
    percentage = percentage or 0.2
    return (active_ratio > percentage)
end

-- Translate a rectangle image to a single-digit number, by comparing the
-- image with pre-saved digit images one by one, and find the one with
-- the shortest 2-norm distance. Note galaga_image.digit[10] is the
-- pre-saved image of '0'.
local function rect_to_digit(rect)
    -- assert(rect:isSameSizeAs(galaga_image.digit[1]))
    local diffs = torch.DoubleTensor(10)
    for i = 1, 10 do diffs[i] = torch.dist(rect, galaga_image.digit[i]) end
    _, m = torch.min(diffs, 1)
    return (m[1] % 10)
end

-- Read current score of the game. The input 'img' is torch.ByteTensor.
-- This function tries to read the score by checking the digit in ones,
-- then in tens, in hundreds, up to 6 digits in total.
function galaga.get_score(img)
    local score = 0
    local rect
    for i = 1, 6 do
        local loc = galaga_image.score_loc
        -- slice out the rectangle and convert it to torch.DoubleTensor
        rect = img[{ {}, {loc[i].h1, loc[i].h2}, {loc[i].w1, loc[i].w2} }]:double()
        if not is_icon_present(rect) then break end
        score = score + rect_to_digit(rect) * math.pow(10, i-1)
    end
    return score
end

-- Read number of lives (remaining fighters) of the game.
function galaga.get_lives(img)
    local lives = 0
    local rect
    for i = 1, 3 do
        local loc = galaga_image.fighter_loc
        -- slice out the rectangle and convert it to torch.DoubleTensor
        rect = img[{ {}, {loc[i].h1, loc[i].h2}, {loc[i].w1, loc[i].w2} }]:double()
        if not is_icon_present(rect, 0.5) then break end
        lives = lives + 1
    end
    return lives
end

-- Check whether "HIGH SCORE" is present at the top-right corner of the
-- game image.
function galaga.has_HIGH(img)
    local loc = galaga_image.high_loc
    local rect = img[{ {}, {loc.h1, loc.h2}, {loc.w1, loc.w2} }]:double()
    -- assert(rect:isSameSizeAs(galaga_image.high))
    local abs_diff = rect:csub(galaga_image.high):abs()
    local diff_ratio = abs_diff[abs_diff:ge(32)]:numel() / abs_diff:numel()
    return (diff_ratio < 0.2)
end

-- Check whether there is any flag present at the lower-right corner of
-- the game image. This is used to determine whether the game is active.
function galaga.has_Flag(img)
    local loc = galaga_image.flag_loc
    local rect = img[{ {}, {loc.h1, loc.h2}, {loc.w1, loc.w2} }]:double()
    return is_icon_present(rect, 0.5)
end

-- Check whether "- RESULT -" is present at the center part of the
-- game image. This is used to determine "GAME OVER" condition.
function galaga.has_RESULT(img)
    local loc = galaga_image.result_loc
    local rect = img[{ {}, {loc.h1, loc.h2}, {loc.w1, loc.w2} }]:double()
    -- assert(rect:isSameSizeAs(galaga_image.high))
    local abs_diff = rect:csub(galaga_image.result):abs()
    local diff_ratio = abs_diff[abs_diff:ge(32)]:numel() / abs_diff:numel()
    return (diff_ratio < 0.2)
end

return galaga

