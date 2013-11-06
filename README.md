### SYNOPSIS
`love-release.sh [OPTIONS] [FILES...]`

### DESCRIPTION
You can use love-release.sh to generate Love2D executables for Linux, OS X, Windows (x86 and x86_64), 
as specified in love2d.org.
An Internet connection is required. The script uses wget, zip and unzip commands.

By default, the script generates releases for every system. But if you add options, 
it will generate releases only for the specified systems.

A directory (default is `./releases`) will be created, and filled with the zipped releases:
`YourGame-win-x86.zip`, `YourGame-win-x64.zip`, `YourGame-osx.zip` and `YourGame.love`.

### OPTIONS
- *-h*,  help
- *-l*,  generates a .love file
- *-m*,  generates a Mac OS X app
- *-w*,  generates Windows x86 and x86_64 executables
  - *-w32*,  generates Windows x86 executable 
  - *-w64*,  generates Windows x86_64 executable
- *-n*,  project's name. By default, the directory's name is used
- *-r*,  release directory. By default, a subdirectory called `releases` is created
- *-u*,  company name. Provide it for OSX CFBundleIdentifier, otherwise USER is used
- *-v*,  love version. Default is 0.8.0. Prior to it, no special Win64 version is available
- *--refresh*,  refresh the cache located in `~/.cache/love-release`

### SEE ALSO
- [https://www.love2d.org](https://www.love2d.org)
- [https://www.love2d.org/wiki/Game_Distribution](https://www.love2d.org/wiki/Game_Distribution)
