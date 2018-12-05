# love-release
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)
[![Build Status](https://travis-ci.org/MisterDA/love-release.svg?branch=master)](https://travis-ci.org/MisterDA/love-release)
[![Coverage Status](https://coveralls.io/repos/github/MisterDA/love-release/badge.svg?branch=master)](https://coveralls.io/github/MisterDA/love-release?branch=master)
[![LuaRocks](https://img.shields.io/badge/LuaRocks-blue.svg)](https://luarocks.org/modules/rucikir/love-release)
![Lua](https://img.shields.io/badge/Lua-5.1%2C%20JIT-blue.svg)

[Lua][lua] script that makes [LÖVE][love] game release easier (previously
Bash script).\
Automates LÖVE [Game Distribution][game_dist].\
LÖVE [forum topic][forum_topic].\
Available as a [LuaRocks 3][luarocks] [package][package].

## Features
love-release makes your LÖVE game release easier. love-release can
create from your sources: Windows executables, MacOS X applications,
Debian packages, and simple LÖVE files.

love-release creates only one LÖVE file per release directory and
keeps it synced with your sources.

love-release can extract its informations from the environment: it
guesses your game's title from the directory where it's stored,
selects by default the latest LÖVE version from the web or uses its
latest bundled LÖVE version, then parses the `conf.lua` file to
extract even more informations such as the real LÖVE version your
project uses.

### Usage
```
Usage: love-release [-D] [-M] [-a <author>] [-b] [-d <desc>]
       [-e <email>] [-l <love>] [-p <package>] [-t <title>] [-u <url>]
       [--uti <uti>] [-v <v>] [-X <exclude>] [--version] [-h] [<release>] [<source>]
       [-W [32|64]]

Makes LÖVE games releases easier !

Arguments:
   release               Project release directory.
   source                Project source directory.

Options:
   -D                    Debian package.
   -M                    MacOS X application.
   -W [32|64]            Windows executable.
   -a <author>, --author <author>
                         Author full name.
   -b                    Compile new or updated files to LuaJIT bytecode.
   -d <desc>, --desc <desc>
                         Project description.
   -e <email>, --email <email>
                         Author email.
   -l <love>, --love <love>
                         LÖVE version to use.
   -p <package>, --package <package>
                         Package and command name.
   -t <title>, --title <title>
                         Project title.
   -u <url>, --url <url> Project homepage url.
   --uti <uti>           Project Uniform Type Identifier.
   -x <exclude_pattern>, --exclude <exclude_pattern>
                         Exclude file patterns.
   -v <v>                Project version.
   --version             Show love-release version and exit.
   -h, --help            Show this help message and exit.

For more info, see https://github.com/MisterDA/love-release
```

### Configuration
love-release prints to the command-line a Lua table containing the
informations it uses to generate your project. These informations can
be stored in your `conf.lua` file to be used later.

```lua
function love.conf(t)
  t.releases = {
    title = nil,              -- The project title (string)
    package = nil,            -- The project command and package name (string)
    loveVersion = nil,        -- The project LÖVE version
    version = nil,            -- The project version
    author = nil,             -- Your name (string)
    email = nil,              -- Your email (string)
    description = nil,        -- The project description (string)
    homepage = nil,           -- The project homepage (string)
    identifier = nil,         -- The project Uniform Type Identifier (string)
    excludeFileList = {},     -- File patterns to exclude. (string list)
    releaseDirectory = nil,   -- Where to store the project releases (string)
  }
end
```

## Installation

### Dependencies
love-release is only installable through LuaRocks and highly depends
on LuaRocks internal API. love-release is currently built on LuaRocks
3.0.x. LuaRocks API is not meant to be stable, and a future update
could break love-release.

#### Required
- [libzip][libzip] and its headers for lua-libzip.
- Other libraries are automatically installed, but let's give them
  some credit: [luafilesystem][lfs], [loadconf][loadconf],
  [middleclass][middleclass], [semver][semver].

#### Optional
- `love` can be used to determine your system LÖVE version.
- `fakeroot` and `dpkg-deb` are required to create Debian packages.
- [LuaJIT][luajit] can be used to compile your sources, either with
  `luarocks-luajit` or with `luajit` if it is installed.

##### Lua binding to libzip

love-release depends on a Lua binding to [libzip][libzip]. I have
forked [brimworks/lua-zip][brimworks-lua-zip] to
[misterda/lua-zip][misterda-lua-zip] in order integrate new features,
and published the fork under my namespace in LuaRocks,
[rucikir/lua-zip][rucikir-lua-zip-rock].

### Install

```sh
# latest stable version
luarocks install love-release

# development version
luarocks install --server=http://luarocks.org/dev love-release
```

### Remove Bash version
You may have previously installed the Bash version of
love-release. You can remove it with the following piece of code. Take
the time to assure yourself that the paths are correct and match your
installation of love-release.

```sh
rm -rf '/usr/bin/love-release'
rm -rf '/usr/share/love-release'
rm -rf '/usr/share/man/man1/love-release.1.gz'
rm -rf '/usr/share/bash-completion/completions/love-release' '/etc/bash_completion.d/love-release'
```

## Contribute
The documentation of love-release internals is written with [LDoc][ldoc].
Generate it by running `ldoc .`.
I currently do not plan to continue the development of the Bash script,
or even to fix it. If there appears to be any need for it, let me know
and I might consider doing so.
Every bug report or feature request is gladly welcome !

[forum_topic]: https://love2d.org/forums/viewtopic.php?t=75387
[game_dist]: https://www.love2d.org/wiki/Game_Distribution
[ldoc]: https://github.com/stevedonovan/LDoc
[lfs]: https://github.com/keplerproject/luafilesystem
[libzip]: http://www.nih.at/libzip/
[love]: https://www.love2d.org/
[lua]: http://www.lua.org/
[luajit]: http://luajit.org/
[luarocks]: https://luarocks.org/
[brimworks-lua-zip]: https://github.com/brimworks/lua-zip
[misterda-lua-zip]: https://github.com/misterda/lua-zip
[rucikir-lua-zip-rock]: https://luarocks.org/modules/rucikir/lua-zip
[loadconf]: https://github.com/Alloyed/loadconf
[middleclass]: https://github.com/kikito/middleclass
[package]: https://luarocks.org/modules/rucikir/love-release
[semver]: https://github.com/kikito/semver.lua
