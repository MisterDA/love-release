### NAME
`love-release.sh` -- Bash script to generate Love 2D game releases

### INSTALLATION
Clone and run as root `install.sh`, or edit `install.sh` to choose
locations in user-space.  
Close and reopen your terminal to make completion available, or execute :  
`. /etc/bash_completion.d/love-release`

### SYNOPSIS
`love-release.sh [-adlmw] [-n project_name] [-r release_dir] [-v love_version] [FILES...]`

### DESCRIPTION
love-release.sh can be used to generate Love 2D game applications
and get over the fastidious zipping commands you had to do.  

The script fully supports Windows, MacOS either on x86 or x64,
Debian and Android packages.  
It needs an Internet connection to download Love files,
and relies on `curl`, `zip` and `unzip` commands.  
To set the default Love version to use,
you can edit the very beginning of the script.  
If `lua` and a `conf.lua` file are found,
it will automatically detect which version your project uses.  

### OPTIONS
`-h`     Print a short help  
`--help` Print this longer help

#### OPERATING SYSTEMS
`-a` Create an Android package.
     In order to create an Android package, you must have installed the Android SDK.
     See [Building LÖVE for Android](https://bitbucket.org/MartinFelis/love-android-sdl2/wiki/Building_L%C3%96VE_for_Android_-_Linux),
     but there is no need to install the [LÖVE port to Android](https://bitbucket.org/MartinFelis/love-android-sdl2),
     as the script will handle this by itself.
     You also might want to provide more informations about it.
     See the ANDROID section below.

`-d` Create a deb package. Aimed at Debian and Ubuntu derivatives.
     In order to create a Debian package, you must provide more informations about it.
     See the DEBIAN section below.

`-l` Create a plain Love file. It is just a zip of your sources, renamed in \*.love.
     Mostly aimed at Linux players or developers and the most common distribution process.

`-m` Create MacOS application.
     Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
     If you are targeting one of these, your project must be developped with Love 0.8.0 or lower.
     Depending on the Love version used, the script will choose which one,
     between x64 only or Universal Build to create.

`-w` Create Windows application.
     Starting with Love 0.8.0, a release is specially available for Windows x64.
     If you are targeting one of these, your project must be developed with Love 0.8.0 or newer.
     Remember that x86 is always backwards compatible with x64.
     Depending on the Love version used, the script will choose which one,
     between x64 and x86 or x86 only to create.  
`-w32`  Create Windows x86 executable only  
`-w64`  Create Windows x64 executable only

#### PROJECT OPTIONS
`-n`  Set the projects name. By default, the name of the current directory is used.

`-r`  Set the release directory. By default, a subdirectory called releases is created.

`-v`  Love version. Default is 0.9.1.
      Starting with Love 0.8.0, a release is specially available for Windows x64.
      Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.

`-x`  Exclude file or directory.

`--description`      Set the description of your project.

`--homepage`         Set the homepage of your project.

#### WINDOWS
`--win-icon`    Path to an ico file to use.

#### MAC OS X
`--osx-icon`               Path to an icns file to use.  
`--osx-maintainer-name`    Set the maintainer’s name. Provide it for OS X CFBundleIdentifier.

#### DEBIAN
`--deb-icon`             Path to a single folder where icons are stored.
                         To be properly recognized, icons filename must contain `YYxYY`,
                         where `YY` is the resolution of the icon.
                         SVG files are recognized if suffixed with `.svg`.
                         Other files will be ignored.  
`--maintainer-email` Set the maintainer’s email.  
`--deb-maintainer-name`  Set the maintainer’s name.  
`--deb-package-name`     Set the name of the package and the command that will be used to launch your game.
                         By default, it is the name of your project converted to lowercase,
                         with eventual spaces replaced by dashes.  
`--deb-package-version`  Set the version of your package.  

#### ANDROID
Note that every argument passed to the options should be alphanumerical,
with eventual underscores (i.e. [a-zA-Z0-9\_]), otherwise you'll get errors.  
`--activity`            The name of the class that extends GameActivity.
                        By default it is the name of the project with ‘Activity’ appended,
                        eventual spaces and dashes replaced by underscores.  
`--apk-maintainer-name` Set the maintainer’s name.
                        It must be only alphanumerical characters, with eventual underscores.  
`--apk-package-name`    Set the name of the package.
                        By default, it is the name of your project, with eventual spaces replaced by underscores.  
`--apk-package-version` Set the version of your package.   
`--update-android`      Update the love-android-sdl2.git repository used in the cache.  

#### OTHERS
`--clean`     Clean the cache located in `~/.cache/love-release`.
              One can replace the Love files there.  
`--config`    Pass a configuration file as argument.
              It describes which build you want to make, with what options.
              See `config.ini`.

#### MODULES
The script is modular.
Each different platform is handled by a subscript stored in `scripts`.
If you’d like to add the support of another platform,
or your own build script, see `scripts/example.sh`.

#### ICONS
The script doesn’t yet handle the process of creating icons,
but if provided it can use them.

- if you want to create MacOS icons (.icns), and you are
  - running MacOS, then check [iconutil](https://developer.apple.com/library/mac/documentation/userexperience/conceptual/applehiguidelines/IconsImages/IconsImages.html).
  - running GNU/Linux, then check [libicns](http://icns.sourceforge.net/).
- if you want to create Windows icons (.ico), you can
  - use [icoutils](http://www.nongnu.org/icoutils/) to create the icon,
  - then [Wine](http://www.winehq.org/) and [Resource Hacker](http://www.angusj.com/resourcehacker/) to set the icon.
    This last step can be automatically done, assuming Wine is installed.

### SEE ALSO
[https://www.love2d.org](https://www.love2d.org)  
[https://www.love2d.org/wiki/Game_Distribution](https://www.love2d.org/wiki/Game_Distribution)  
[https://www.github.com/MisterDA/love-release](https://www.github.com/MisterDA/love-release)

### THANKS
The work done on Debian packaging is highly inspired by what [josefnpat](http://josefnpat.com/) did.
Thanks to him !

