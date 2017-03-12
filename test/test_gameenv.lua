--------------------------------------------------------------------------------
--
-- Test code of "gameenv" module
--
-- This should be run from the top directory: (hit Ctrl-C to end it)
-- 
--   $ qlua test/test_gamenv.lua [options]
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-24
--------------------------------------------------------------------------------

require 'torch'

cmd = torch.CmdLine()
cmd:text()
cmd:text('options:')
cmd:option('-games', 100, 'play this many games and calculate average score')
cmd:option('-actrep', 2, 'how many steps to repeat an action')
cmd:option('-plot', false, 'plot histogram at the end')
cmd:text()
opt = cmd:parse(arg or {})

gameenv = require 'gameenv/gameenv-old'

gameenv.init('galaga')
actions = gameenv.get_actions()
history = {}

for i = 1, opt.games do
    local terminal = false
    local cnt = 0
    gameenv.new_game()
    while not terminal do
        cnt = cnt + 1
        if cnt % opt.actrep == 0 then
            -- take a random action
            _, _, terminal = gameenv.step(actions[math.random(#actions)])
        else
            _, _, terminal = gameenv.step()
        end
    end
    gameenv.step(0)  -- release all buttons
    print(('Game #%3d, score = '):format(i) .. gameenv.get_score())
    history[#history + 1] = gameenv.get_score()
end

gameenv.cleanup()

hh = torch.Tensor(history)
print()
print('Score average = ' .. (hh:sum() / hh:numel()) ..
      ', min = ' .. hh:min() ..
      ', max = ' .. hh:max())

if opt.plot then
    require 'gnuplot'
    gnuplot.hist(hh, hh:numel() / 5)
end
