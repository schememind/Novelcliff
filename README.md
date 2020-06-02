# Novelcliff
ASCII platformer game (still work in progress).

Open any text file on your hard drive and it is then transformed into a platformer game with a goal to reach the bottom of the file, earning points by collecting coins and eliminating enemies.

![Alt Text](https://media.giphy.com/media/UpIo5gYhZ3eX0kMvqI/giphy.gif)

## Build
Novelcliff is written in [D](https://dlang.org/) language, utilizing [Tkd](https://github.com/nomad-software/tkd) library for graphical user interface. The most convenient way to build the game from source code is by using [DUB](https://dub.pm/getting_started) package manager:
- Build for 32-bit architecture: `dub build --config=gui --build=plain --arch=x86`
- Build for 64-bit architecture: `dub build --config=gui --build=plain --arch=x86_64`
- Build step-by-step command line debugging profile: `dub build --config=dbg --build=debug`
