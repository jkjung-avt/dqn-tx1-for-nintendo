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
cmd:option('-actrep', 2, 'how many times to repeat action')
cmd:option('-name', 'DQN_galaga', 'filename for saving network and training history')
cmd:option('-network', '', 'reload pretrained network')
cmd:option('-agent', 'NeuralQLearner', 'name of agent file to use')
cmd:option('-agent_params', 'lr=0.00025,ep=1,ep_end=0.1,ep_endt=100000,discount=0.99,hist_len=4,learn_start=5000,replay_memory=100000,update_freq=4,n_replay=1,network="convnet_atari3",preproc="net_downsample_2x_full_y",state_dim=7056,minibatch_size=32,rescale_r=1,ncols=1,bufferSize=512,valid_size=500,target_q=10000,clip_delta=1,min_reward=-1,max_reward=1', 'string of agent parameters')
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-steps', 5*10^7, 'number of training steps to perform')
cmd:option('-toc_freq', 10^3, 'frequency of timing output')
cmd:option('-prog_freq', 10^4, 'frequency of progress output')
cmd:option('-save_freq', 10^5, 'the model is saved every save_freq steps')
cmd:option('-save_versions', 10^5, 'save models with versions (0: only lastest one)')
cmd:option('-verbose', 10, 'higher number means more information')
cmd:option('-gpu', 0, 'gpu flag (negative number means not using GPU)')
cmd:option('-cudnn', true, 'use cudnn (only valid if gpu is set)')
cmd:text()

local opt = cmd:parse(arg)

local game_env = require 'gameenv/gameenv'
game_env.init(opt.env, opt.display_freq)
local game_actions = game_env.get_actions()
-- run setup to load agent
package.path = package.path .. ';./dqn-deepmind/?.lua'
require 'initenv'
_, _, agent, opt = setup(opt, game_env, game_actions)

local steps = 0

--
-- Main Loop
--
game_env.new_game()
screen, reward, terminal = game_env.step(0)
if opt.verbose > 1 then print('Training on the 1st game...') end

while steps < opt.steps do
    w = image.display({image = screen, win = w})
    steps = steps + 1
    --local action_index, bestq = agent:perceive(reward, screen, terminal)

    if not terminal then
        if steps % opt.actrep == 0 then
            local a = torch.random(1 ,#game_actions)
            screen, reward, terminal = game_env.step(game_actions[a])
        else
            screen, reward, terminal = game_env.step()
        end
    else
        -- Game Over
        game_env.step(0)  -- release all buttons
        print('Game Over, score = ' .. game_env.get_score())
        break
    end
end

game_env.cleanup()
