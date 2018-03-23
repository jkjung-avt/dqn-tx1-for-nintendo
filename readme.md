# dqn-tx1-for-nintendo

Aka, a Deep Q Learner Network (DQN) on NVIDIA Jetson TX1 which learns to play Nintendo Famicom Mini games.

I'm developing an AI program, based on DeepMind's DQN, on Jetson TX1 to play Nintendo games. I use this repository to keep track of all source code of the project. Please refer to the following blog posts for more information.

[DQN (RL Agent) on TX1 for Nintendo Famicom Mini](https://jkjung-avt.github.io/dqn-tx1-for-nintendo/)

[Nintendo AI Agent Training in Action, Finally...](https://jkjung-avt.github.io/training-in-action/)

<iframe width="560" height="315" src="https://www.youtube.com/embed/j-JKPok_1os" frameborder="0" allowfullscreen></iframe>

Installation Instructions
-------------------------

The following are required for this **dqn-tx1-for-nintendo** to work.

* NVIDIA Jetson TX1 board with a HDMI input (/dev/video0). I actually used [AVerMedia's EX711-AA TX1 carrier board](http://www.avermedia.com/professional/product/ex711_aa/overview), and installed L4T R24.2.1 on it.
* [Nintendo Famicom Mini](https://jkjung-avt.github.io/nintendo-famicom-mini/), of which the HDMI video output is connected to video input (/dev/video0) of the TX1 carrier board. The game console would be running ["Galaga"](https://jkjung-avt.github.io/galaga/).
* TX1 GPIO connections to [the joystick of Nintendo Famicom Mini](https://jkjung-avt.github.io/gpio-circuit/).
* (Preferred) [A swap partition for TX1](https://jkjung-avt.github.io/swap-on-tx1/).
* [GPIO access permission for non-root user (ubuntu) on TX1](https://jkjung-avt.github.io/gpio-non-root/).
* [Torch7](https://jkjung-avt.github.io/torch7-on-tx1/).

Training DQN on Nintendo Games
------------------------------

To build the code on Jetson TX1, just run `make` at the project root diretory.

```shell
 $ make
```
Then execute `train-deepmind.lua` to train the DQN (use `-h` to see help messages).

```shell
 $ th ./train-deepmind.lua
```

Modules within This Project
---------------------------

The following modules resides in the corresponding subdirectories of the repository. There are also test scripts for most modules as described in the next section.

* 'vidcap' - for HDMI video capture, reference: [Capturing HDMI Video in Torch7](https://jkjung-avt.github.io/vidcap-in-torch7/)
* 'galaga' - for parsing Galaga game screens to determine state (score, lives, etc.) of the game
* 'gpio' - for controlling GPIO outputs, reference: [Accessing Hardware GPIO in Torch7](https://jkjung-avt.github.io/gpio-in-torch7/)
* 'imshow' - for displaying video/images, reference: [Getting Around Memory Leak Problem of Torch7's image.display() Interface](https://jkjung-avt.github.io/imshow/)
* 'gamenev' - game enviornment API for Nintendo Famicom Mini, reference: [Galaga Game Environment](https://jkjung-avt.github.io/galaga-gameenv/)
* 'dqn-deepmind' - Google DeepMind's Deep Q Learner Networki, for which I've applied cuDNN to speed up its training, reference: [Using cuDNN to Speed Up DQN Training on Jetson TX1](https://jkjung-avt.github.io/dqn-cudnn/)

Testing Individual Modules
--------------------------

All test scripts are organized in the 'test' subdirectory. They are meant to be run from the project root directory. Most of the test scripts accept cmdline options (use `-h` to see help messages).

```shell
 $ qlua test/test_vidcap.lua
 $ qlua test/test_galaga.lua
 $ th   test/test_gpio.lua
 $ th   test/test_imshow.lua
 $ th   test/test_gameenv.lua
```
