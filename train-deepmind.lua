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
cmd:option('-display_freq', 1, 'frequency of game image display')
cmd:option('-actrep', 2, 'how many steps to repeat an action')
cmd:option('-name', 'DQN_galaga', 'filename for saving network and training history')
cmd:option('-network', '', 'reload pretrained network')
cmd:option('-agent', 'NeuralQLearner', 'name of agent file to use')
cmd:option('-agent_params', 'lr=0.00025,ep=1,ep_end=0.1,ep_endt=100000,discount=0.99,hist_len=4,learn_start=10000,replay_memory=100000,update_freq=6,n_replay=1,network="convnet_atari3",preproc="net_downsample_2x_full_y",state_dim=7056,minibatch_size=8,rescale_r=1,ncols=1,bufferSize=8,target_q=10000,clip_delta=1,min_reward=-1,max_reward=1', 'string of agent parameters')
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-steps', 5*10^7, 'number of training steps to perform')
cmd:option('-save_freq', 10^5, 'the model is saved every save_freq steps')
cmd:option('-save_versions', 10^5, 'save models with versions (0: only lastest one)')
cmd:option('-extra_train', 1600, 'how many extra training steps to do at end of each episode')
cmd:option('-verbose', 10, 'higher number means more information')
cmd:option('-gpu', 0, 'gpu flag (negative number means not using GPU)')
cmd:option('-cudnn', true, 'use cudnn (only valid if gpu is set)')
cmd:text()

local opt = cmd:parse(arg)

--
-- Initialization
--
game_env = require 'gameenv/gameenv-threaded'
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

    local percv_history = {}
    local train_history = {}
    local skip_train = false

    -- Inner loop, stepping through the game until terminal == true
    while not terminal do
        local action_index = nil  -- nil means repeat previous action
        if steps % opt.actrep == 0 then
            local xx = torch.tic()
            --action_index = torch.random(1 ,#game_actions)
            action_index = agent:perceive(reward, screen, terminal)
            percv_history[#percv_history + 1] = torch.toc(xx)
            -- skip the next training if this agent:perceive() takes too long
            if percv_history[#percv_history] > 0.01 then skip_train = true end
        end
        screen, reward, terminal = game_env.step(game_actions[action_index])
        if action_index then stats[action_index] = stats[action_index] + 1 end
        steps = steps + 1
        --if steps % 1000 == 1 then collectgarbage() end
        if steps % opt.save_freq == 0 then ready_to_save = true end

        -- do some training if previous agent:perceive() did not take too long
        if agent.numSteps > agent.learn_start and
           agent.numSteps % agent.update_freq == 0 then
            if not skip_train then
                local xx = torch.tic()
                for i = 1, agent.n_replay do
                    agent:qLearnMinibatch()
                end
                train_history[#train_history + 1] = torch.toc(xx)
                -- skip the next training if this training takes too long
                if train_history[#train_history] > 0.05 then skip_train = true end
            else
                skip_train = false
            end
        end
    end

    -- Game is over; let the agent know about it
    agent:perceive(reward, screen, terminal)
    steps = steps + 1
    game_env.step(0)  -- release all buttons
    --assert((steps / opt.actrep) + 1 == agent.numSteps, 'trainer step: ' .. steps .. ' & agent.numSteps: ' .. agent.numSteps)

    if #train_history > 1 then
        local px = torch.Tensor(percv_history)
        print('\n--- perceive time average = ' .. px:sum() / px:numel() .. ', max = ' .. px:max() .. ', min = ' .. px:min())
        local tx = torch.Tensor(train_history)
        print('--- trained for ' .. #train_history .. ' times')
        print('--- training time average = ' .. tx:sum() / tx:numel() .. ', max = ' .. tx:max() .. ', min = ' .. tx:min())
    end

    local game_time = torch.toc(tic)
    local diff = steps - tic_steps
    print(string.format('\n*** %d steps (%.2f s) done in %.2f s', diff, diff / 30.0, game_time))

    stats:div(stats:sum())  -- calculate percentage of each action
    io.write('Distribution of actions: ')
    for i = 1, stats:size(1) do io.write(string.format('%.2f, ', stats[i])) end
    print('Score = ' .. game_env.get_score() .. '\n')
    games = games + 1
    score_history[games] = game_env.get_score()
    steps_history[games] = diff
    stats_history[games] = stats:clone()

    -- do more training, before starting the next game...
    if agent.numSteps > agent.learn_start then
        for i = 1, opt.extra_train do agent:qLearnMinibatch() end
    end

    print('Total steps: ' .. steps)
    agent:report()
    collectgarbage()

    -- save the model periodically
    if ready_to_save or steps >= opt.steps then
        local filename = opt.name
        if opt.save_versions > 0 then
            filename = filename .. "_" .. math.floor(steps / opt.save_versions)
        end
        torch.save(filename .. '.t7',
                  {model = agent.network,
                   score_history = score_history,
                   steps_history = steps_history,
                   stats_history = stats_history,
                   arguments = opt})
        print('Saved: ' .. filename .. '.t7')
        ready_to_save = false
    end

    collectgarbage()
    if steps >= opt.steps then break end  -- the whole training is done
end

hh = torch.Tensor(score_history)
print('\nScore average = ' .. hh:sum() / hh:numel() .. ', min = ' .. hh:min() .. ', max = ' .. hh:max())

game_env.cleanup()
