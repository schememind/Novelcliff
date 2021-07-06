# Novelcliff
## Summary
ASCII platformer game (still in development).

Turn any text file into platformer game. Start in the beginning of the file, jump over the words, pick them up to clear your way, battle annoying monsters by throwing these words at them, collect valuable coins, all that with the goal of making your way down to the end of the file.

![Alt Text](https://media.giphy.com/media/UpIo5gYhZ3eX0kMvqI/giphy.gif)

## Install
TODO: not available yet

## Build from source
### Common
Novelcliff is written in [D](https://dlang.org/) language, utilizing [Tkd](https://github.com/nomad-software/tkd) library for graphical user interface. The most convenient way to build the game from source is by using [DUB](https://dub.pm/getting_started) package manager:
- Build for 32-bit architecture: `dub build --config=guitkd --build=release --arch=x86`
- Build for 64-bit architecture: `dub build --config=guitkd --build=release --arch=x86_64`
- Build step-by-step command line debugging profile: `dub build --config=dbg --build=debug`
### Building on Linux
Tcl/Tk libraries are required to run the compiled game. The same applies to linking stage of the build process. Run the following command to install these libraries:

For Debian based distros: `sudo apt install libtcl8.6 libtk8.6`

If linking error is received during build process (even after installation of Tcl/Tk libraries), then creating symbolic links to these libraries may help:

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/libtcl8.6.so.0 /usr/lib/libtcl.so
sudo ln -s /usr/lib/x86_64-linux-gnu/libtk8.6.so.0 /usr/lib/libtk.so
```
