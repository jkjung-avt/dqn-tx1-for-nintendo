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
cmd:option('-actstep', 2, 'take one action per this many game frames')
cmd:option('-plot', false, 'plot histogram at the end')
cmd:text()
opt = cmd:parse(arg or {})

gameenv = require 'gameenv/gameenv'

gameenv.init('galaga')
actions = gameenv.get_actions()
history = {}

for i = 1, opt.games do
    local terminal = false
    local cnt = 0
    gameenv.new_game()
    while not terminal do
        cnt = cnt + 1
        if cnt % opt.actstep == 0 then
            -- take a random action
            _, _, terminal = gameenv.step(actions[math.random(#actions)])
        else
            _, _, terminal = gameenv.step()
        end
    end
    print(('Game #%3d, score = '):format(i) .. gameenv.get_score())
    history[#history + 1] = gameenv.get_score()
end

gameenv.cleanup()

hh = torch.Tensor(history)
print()
print('Average score = ' .. (hh:sum() / hh:numel()) ..
      ', min = ' .. hh:min() ..
      ', max = ' .. hh:max())
if opt.plot then
    require 'gnuplot'
    gnuplot.hist(hh, hh:numel() / 5)
end
