# dqn-tx1-for-nintendo

Aka, a DQN on TX1 which learns to play Nintendo console games.

I'm developing an AI program, based on DeepMind's DQN, on NVIDIA Jetson TX1 to play Nintendo Famicom Mini games. I use this repository to keep track of all source code of the project. Please refer to my blog for more information.

[https://jkjung-avt.github.io/nintendo-famicom-mini/](https://jkjung-avt.github.io/nintendo-famicom-mini/)

Installation Instructions
-------------------------

The following are required for this **dqn-tx1-for-nintendo** to work.

* NVIDIA Jetson TX1 board with L4T R24.2.1. I actually used [AVerMedia's EX711-AA TX1 carrier board](http://www.avermedia.com/professional/product/ex711_aa/overview).
* [Nintendo Famicom Mini](https://www.nintendo.co.jp/clv/), of which the HDMI video output is connected to video input (/dev/video0) of the TX1 carrier board. The game console would be running the "Galaga" game.
* TX1 GPIO connections to the joystick of Nintendo Famicom Mini.
* (Preferred) A swap partition for TX1.
* GPIO access permission for non-root user (ubuntu) on TX1.
* Torch7, with qlua.

Training DQN on Atari Games
---------------------------

To build the code, just run `make` at the project root diretory.

```shell
 $ make
```
Then execute `run.lua` to train the DQN.

```shell
 $ qlua ./run.lua
```

Modules within This Project
---------------------------

* 'vidcap' - for HDMI video capture, reference: [https://jkjung-avt.github.io/vidcap-in-torch7/](https://jkjung-avt.github.io/vidcap-in-torch7/)
* 'dqn' - DeepMind's Deep Q-function Network

Testing Individual Modules
--------------------------

All test programs are organized in the 'test' subdirectory. They are meant to be run from the project root directory.

```shell
 $ qlua test/test_vidcap.lua
```
