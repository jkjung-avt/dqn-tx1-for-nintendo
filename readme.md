# dqn-tx1-for-nintendo

Aka, a Deep Q Learner Network (DQN) on NVIDIA Jetson TX1 which learns to play Nintendo Famicom Mini games.

I'm developing an AI program, based on DeepMind's DQN, on Jetson TX1 to play Nintendo games. I use this repository to keep track of all source code of the project. Please refer to my blog for more information.

[https://jkjung-avt.github.io/nintendo-famicom-mini/](https://jkjung-avt.github.io/nintendo-famicom-mini/)

Installation Instructions
-------------------------

The following are required for this **dqn-tx1-for-nintendo** to work.

* NVIDIA Jetson TX1 board with a HDMI input (/dev/video0). I actually used [AVerMedia's EX711-AA TX1 carrier board](http://www.avermedia.com/professional/product/ex711_aa/overview), and installed L4T R24.2.1 on it.
* [Nintendo Famicom Mini](https://jkjung-avt.github.io/nintendo-famicom-mini/), of which the HDMI video output is connected to video input (/dev/video0) of the TX1 carrier board. The game console would be running ["Galaga"](https://jkjung-avt.github.io/galaga/).
* TX1 GPIO connections to [the joystick of Nintendo Famicom Mini](https://jkjung-avt.github.io/gpio-circuit/).
* (Preferred) [A swap partition for TX1](https://jkjung-avt.github.io/swap-on-tx1/).
* [GPIO access permission for non-root user (ubuntu) on TX1](https://jkjung-avt.github.io/gpio-non-root/).
* [Torch7](https://jkjung-avt.github.io/torch7-on-tx1/), with qlua.

Training DQN on Nintendo Games
------------------------------

To build the code, just run `make` at the project root diretory.

```shell
 $ make
```
Then execute `run.lua` to train the DQN. (This part is still under development...)

```shell
 $ qlua ./run.lua
```

Modules within This Project
---------------------------

The following modules resides in the corresponding subdirectories of the repository. There are also test scripts for most modules as described in the next section.

* 'vidcap' - for HDMI video capture, reference: [https://jkjung-avt.github.io/vidcap-in-torch7/](https://jkjung-avt.github.io/vidcap-in-torch7/)
* 'galaga' - for parsing Galaga game screens to determine state (score, lives, etc.) of the game
* 'gpio' - for controlling GPIO outputs, reference: [https://jkjung-avt.github.io/gpio-in-torch7/](https://jkjung-avt.github.io/gpio-in-torch7/)
* 'gamenev' - game enviornment API for Nintendo Famicom Mini
* 'dqn' - Google DeepMind's Deep Q Learner Network

Testing Individual Modules
--------------------------

All test scripts are organized in the 'test' subdirectory. They are meant to be run from the project root directory. Most of the test scripts accept cmdline options (use `-h` to see help messages).

```shell
 $ qlua test/test_vidcap.lua
 $ qlua test/test_galaga.lua
 $ th   test/test_gpio.lua
 $ qlua test/test_gameenv.lua
```
