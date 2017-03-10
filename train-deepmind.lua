--------------------------------------------------------------------------------
--
-- train-deepmind.lua
--
-- This program trains DeepMind's DQN on Jetson TX1 to play the Nintendo
-- Famicom Mini game, Galaga.
-- 
--   $ qlua train-deepmind.lua [options]
--
--------------------------------------------------------------------------------
-- jkjung, 2017-03-07
--------------------------------------------------------------------------------

require 'torch'

torch.setdefaulttensortype('torch.FloatTensor')

cmd = torch.CmdLine()
cmd:text()
cmd:text('Train Agent to play Galaga:')
cmd:text()
cmd:text('Options:')
cmd:option('-framework', 'nintendo', 'name of game framework to use')
cmd:option('-env', 'galaga', 'name of game environment to use')
cmd:option('-display_freq', 3, 'frequency of game image display')
cmd:option('-name', 'DQN_galaga', 'filename for saving network and training history')
cmd:option('-network', '', 'reload pretrained network')
cmd:option('-agent', 'NeuralQLearner', 'name of agent file to use')
cmd:option('-agent_params', 'lr=0.00025,ep=1,ep_end=0.1,ep_endt=100000,discount=0.99,hist_len=4,learn_start=10000,replay_memory=100000,update_freq=4,n_replay=1,network="convnet_atari3",preproc="net_downsample_2x_full_y",state_dim=7056,minibatch_size=8,rescale_r=1,ncols=1,bufferSize=64,target_q=10000,clip_delta=1,min_reward=-1,max_reward=1', 'string of agent parameters')
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-steps', 5*10^7, 'number of training steps to perform')
cmd:option('-prog_freq', 10^4, 'frequency of progress output')
cmd:option('-save_freq', 10^5, 'the model is saved every save_freq steps')
cmd:option('-save_versions', 10^5, 'save models with versions (0: only lastest one)')
cmd:option('-verbose', 10, 'higher number means more information')
cmd:option('-gpu', 0, 'gpu flag (negative number means not using GPU)')
cmd:option('-cudnn', true, 'use cudnn (only valid if gpu is set)')
cmd:text()

local opt = cmd:parse(arg)

--
-- Initialization
--
game_env = require 'gameenv/gameenv'
game_env.init(opt.env, opt.display_freq)
game_actions = game_env.get_actions()

-- run setup to load agent
package.path = package.path .. ';./dqn-deepmind/?.lua'
require 'initenv'
_, _, agent, opt = setup(opt, game_env, game_actions)

c = require 'trepl.colorize'

--
-- Main program
--
steps, games = 0, 0
screen, reward, terminal = nil, 0, false
ready_to_save = false
score_history = {} 
steps_history = {}
stats_history = {}
stats = torch.Tensor(#game_actions)

-- Outer loop, each iteration corresponds to 1 episode of full game
while true do
    stats:fill(0)
    game_env.new_game()
    screen, reward, terminal = game_env.step(0)

    local tic = torch.tic()
    local tic_steps = steps

    -- Inner loop, stepping through the game until terminal == true
    while not terminal do
        local action_index = agent:perceive(reward, screen, terminal)
        --local action_index = torch.random(1 ,#game_actions)
        screen, reward, terminal = game_env.step(game_actions[action_index])
        stats[action_index] = stats[action_index] + 1
        steps = steps + 1
        if steps % 1000 == 0 then collectgarbage() end
        if steps % opt.save_freq == 0 then ready_to_save = true end

        -- check to see if we should do some training and reporting
    end

    -- Game is over; let the agent know about it
    agent:perceive(reward, screen, terminal)
    steps = steps + 1
    game_env.step(0)  -- release all buttons
    assert(steps == agent.numSteps, 'trainer step: ' .. steps .. ' & agent.numSteps: ' .. agent.numSteps)

    local game_time = torch.toc(tic)
    local diff = steps - tic_steps
    print(string.format('\n*** %d steps (%.2f s) done in %.2f s', diff, diff / 30.0, game_time))

    stats:div(stats:sum())  -- calculate percentage of each action
    io.write('Distribution of actions: ')
    for i = 1, stats:size(1) do io.write(string.format('%.2f ,', stats[i])) end
    print('Score = ' .. game_env.get_score() .. '\n')
    games = games + 1
    score_history[games] = game_env.get_score()
    steps_history[games] = diff
    stats_history[games] = stats:clone()

    -- save the model periodically
    if ready_to_save then
        local filename = opt.name
        if opt.save_versions > 0 then
            filename = filename .. "_" .. math.floor(steps / opt.save_versions)
        end
        torch.save(filename .. ".t7",
                  {model = agent.network,
                   score_history = score_history,
                   steps_history = steps_history,
                   stats_history = stats_history,
                   arguments = opt})
        ready_to_save = false
    end

    -- do more training...

    agent:report()
    collectgarbage()

    if steps >= opt.steps then break end  -- the whole training is done
end

hh = torch.Tensor(score_history)
print('\nScore average = ' .. hh:sum() / hh:numel() .. ', min = ' .. hh:min() .. ', max = ' .. hh:max())

game_env.cleanup()
