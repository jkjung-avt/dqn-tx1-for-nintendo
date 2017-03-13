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

torch.setdefaulttensortype('torch.FloatTensor')

cmd = torch.CmdLine()
cmd:text()
cmd:text('options:')
cmd:option('-games', 100, 'play this many games and calculate average score')
cmd:option('-actrep', 2, 'how many steps to repeat an action')
cmd:option('-plot', false, 'plot histogram at the end')
cmd:text()
opt = cmd:parse(arg or {})

gameenv = require 'gameenv/gameenv-threaded'

gameenv.init('galaga')
actions = gameenv.get_actions()
history = {}

for i = 1, opt.games do
    local screen, reward, terminal
    local total_reward = 0
    local cnt = 1
    gameenv.new_game()
    screen, reward, terminal = gameenv.step(0)
    local tic = torch.tic()
    while not terminal do
        if cnt % opt.actrep == 0 then
            -- take a random action
            screen, reward, terminal = gameenv.step(actions[torch.random(1, #actions)])
        else
            screen, reward, terminal = gameenv.step()
        end
        assert(screen:dim() == 3)
        assert(screen:size(1) == 1 and screen:size(2) == 84 and screen:size(3) == 84)
        if reward > 0 then total_reward = total_reward + reward end
        cnt = cnt + 1
    end
    gameenv.step(0)  -- release all buttons
    assert(gameenv.get_score() == total_reward)
    print(string.format('Game #%d (expected %.2f s) finished in %.2f s, score = %d', i, cnt / 30.0, torch.toc(tic), gameenv.get_score()))
    history[#history + 1] = gameenv.get_score()
    collectgarbage()
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
