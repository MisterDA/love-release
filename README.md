# love-release
[![License](http://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)
[![Build Status](https://travis-ci.org/MisterDA/love-release.svg?branch=love-release-3)](https://travis-ci.org/MisterDA/love-release)
[![Coverage Status](https://coveralls.io/repos/github/MisterDA/love-release/badge.svg?branch=master)](https://coveralls.io/github/MisterDA/love-release?branch=love-release-3)
[![LuaRocks](https://img.shields.io/badge/LuaRocks-git--1-blue.svg)](https://luarocks.org/modules/rucikir/love-release)
![Lua](https://img.shields.io/badge/Lua-5.1%20%E2%86%92%205.3%2C%20JIT-blue.svg)

[Lua][lua] 5.1 script that makes [LÖVE][love] game release easier (previously Bash script).  
Automates LÖVE [Game Distribution][game_dist].  
LÖVE [forum topic][forum_topic].  
Available as a [LuaRocks][luarocks] [package][package].

## Features
love-release 3 is currently in development. See [#40](https://github.com/MisterDA/love-release/issues/40) for proposals.

### Usage
```
Usage: love-release [--version] [-h]

Makes LÖVE games releases easier !

Options:
   --version             Show love-release version and exit.
   -h, --help            Show this help message and exit.

For more info, see https://github.com/MisterDA/love-release
```

## Installation

### Dependencies
love-release is only installable through LuaRocks and highly depends on LuaRocks internal API. love-release is currently build on LuaRocks 2.3.0. LuaRocks API is not meant to be stable, and a future update could break love-release. As love-release is made for LÖVE, it is written for Lua 5.1.

#### Required
- Lua libraries are automatically installed, but let's give them some credit: [argparse][argparse], [middleclass][middleclass].

### Install

```sh
# latest stable version
luarocks install love-release

# development version
luarocks install --server=http://luarocks.org/dev love-release
```

### Remove Bash version
You may have previously installed the Bash version of love-release. You can remove it with the following piece of code. Take the time to assure yourself that the paths are correct and match your installation of love-release.

```sh
rm -rf '/usr/bin/love-release'
rm -rf '/usr/share/love-release'
rm -rf '/usr/share/man/man1/love-release.1.gz'
rm -rf '/usr/share/bash-completion/completions/love-release' '/etc/bash_completion.d/love-release'
```

## Contribute
The documentation of love-release internals is written with [LDoc][ldoc]. Generate it by running `ldoc .`.  
I do not plan to keep developing the Bash script, not even fixing it. If there appears to be any need for it, let me know and I might consider doing so.  
Every bug report or feature request is gladly welcome !

[argparse]: https://github.com/mpeterv/argparse
[forum_topic]: https://love2d.org/forums/viewtopic.php?t=75387
[game_dist]: https://www.love2d.org/wiki/Game_Distribution
[ldoc]: https://github.com/stevedonovan/LDoc
[love]: https://www.love2d.org/
[lua]: http://www.lua.org/
[luarocks]: https://luarocks.org/
[middleclass]: https://github.com/kikito/middleclass
[package]: https://luarocks.org/modules/rucikir/love-release
