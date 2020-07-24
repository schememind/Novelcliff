# Novelcliff
ASCII platformer game (still work in progress).

Open any text file on your hard drive and it is then transformed into a platformer game with a goal to reach the bottom of the file, earning points by collecting coins and eliminating enemies by throwing words at them.

![Alt Text](https://media.giphy.com/media/UpIo5gYhZ3eX0kMvqI/giphy.gif)

## Build
Novelcliff is written in [D](https://dlang.org/) language, utilizing [Tkd](https://github.com/nomad-software/tkd) library for graphical user interface. The most convenient way to build the game from source code is by using [DUB](https://dub.pm/getting_started) package manager:
- Build for 32-bit architecture: `dub build --config=gui --build=release --arch=x86`
- Build for 64-bit architecture: `dub build --config=gui --build=release --arch=x86_64`
- Build step-by-step command line debugging profile: `dub build --config=dbg --build=debug`
### Building on Linux
Tcl/Tk libraries are required to run the compiled game (as well as to perform linking during the build process). Run the following command to install these:

For Debian based distros: `sudo apt install libtcl8.6 libtk8.6`

If linking error is received during the build process (even after installation of Tcl/Tk libraries), creating symbolic links to these libraries may help:

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/libtcl8.6.so.0 /usr/lib/libtcl.so
sudo ln -s /usr/lib/x86_64-linux-gnu/libtk8.6.so.0 /usr/lib/libtk.so
```
