### NAME
`love-release.sh` -- Bash script to generate Love 2D game releases

### INSTALLATION
First clone the repository, then you have two choices:
- you can build the script and install it on your system, and benefit of command-line completion, man page and extensibility,
- or make an embedded version with every thing you need in one file.

Alternatively, you can change the installation directories by editing the Makefile.

```shell
# Install on your system (assumes root rights)
make
make install

# All-in-one
make embedded
```

To remove love-release, if you haven't changed the default installation directories, run `make remove`.

### SYNOPSIS
`love-release.sh [-ADLMW] [-t project_title] [-r release_dir] [-l love_version] [FILES...]`

### DESCRIPTION
love-release.sh can be used to generate Love 2D game applications
and get over the fastidious zipping commands you had to do.  

The script fully supports Windows, MacOS either on x86 or x64,
Debian and Android packages.  
It needs an Internet connection to download Love files,
and relies on `curl`, `zip` and `unzip` commands.  

### CONFIGURATION
You can install `lua` and add a `conf.lua` to your project to get automatic releases.
See the `conf.lua` file included to see how configuration works.

### OPTIONS
`-h`     Print a short help  
`--help` Print this longer help

#### OPERATING SYSTEMS
`-A` Create an Android package.
     In order to create an Android package, you must have installed the Android SDK.
     See [Building LÖVE for Android](https://bitbucket.org/MartinFelis/love-android-sdl2/wiki/Building_L%C3%96VE_for_Android_-_Linux),
     but there is no need to install the [LÖVE port to Android](https://bitbucket.org/MartinFelis/love-android-sdl2),
     as the script will handle this by itself.
     You also might want to provide more informations about it.
     See the ANDROID section below.

`-D` Create a deb package. Aimed at Debian and Ubuntu derivatives.
     In order to create a Debian package, you must provide more informations about it.
     See the DEBIAN section below.

`-L` Create a plain Love file. It is just a zip of your sources, renamed in \*.love.
     Mostly aimed at Linux players or developers and the most common distribution process.

`-M` Create MacOS application.
     Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
     If you are targeting one of these, your project must be developped with Love 0.8.0 or lower.
     Depending on the Love version used, the script will choose which one,
     between x64 only or Universal Build to create.

`-W` Create Windows application.
     Starting with Love 0.8.0, a release is specially available for Windows x64.
     If you are targeting one of these, your project must be developed with Love 0.8.0 or newer.
     Remember that x86 is always backwards compatible with x64.
     Depending on the Love version used, the script will choose which one,
     between x64 and x86 or x86 only to create.  
`-W32`  Create Windows x86 executable only  
`-W64`  Create Windows x64 executable only

#### PROJECT OPTIONS
You can use the option of a module and append a long option from this list to set a specific
option for a module. For example, the option `--Wauthor` will set the author's name for windows only.

`-a, --author` Set the project's author.

`-d, --description` Set the project's description.

`-e, --email` Set the author's email.

`-i, --icon` Path to icons.

`-l, --love` Love version. Default is 0.9.2.
             Starting with Love 0.8.0, a release is specially available for Windows x64.
             Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.

`-p, --pkg` Set the project's identity.

`-r, --release`  Set the release directory. By default, a subdirectory called releases is created.

`-t, --title`  Set the project's title. By default, the name of the current directory is used.

`-u, --url` Set the project's homepage.

`-v, --version` Set your project's version.

`-x`  Exclude file or directory.

#### WINDOWS
You can create an installer. If you don’t, you will have zip of a folder
containing your game executable and its dlls.
Creating installers and using icons require [Wine](http://www.winehq.org/) to be installed.
When the script installs Resource Hacker or Inno Setup, an install wizard GUI will appear.
Please let everything as is, do not uncheck checkboxes or replace installation directory.  
`--Wicon`       Path to an ico file to use.  
`--Winstaller`  Create an installer with [Inno Setup](http://www.jrsoftware.org/isinfo.php).  
`--Wappid`      Your game ID. You can use a GUID/UUID and generate one with `uuidgen`.
                It should remain the same between updates.
                Mandatory if using an installer, not needed for a simple zip.  
`--Wauthor`     Set the maintainer’s name.
                Mandatory if using an installer, not needed for a simple zip.  
`--Wpkg`        Set the name of your package.
                Mandatory if using an installer, not needed for a simple zip.  
`--Wversion`    Set the version of your package.
                Mandatory if using an installer, not needed for a simple zip.  

#### MAC OS X
`--Micon`       Path to an icns file to use.  
`--Mauthor`     Set the maintainer’s name. Provide it for OS X CFBundleIdentifier.

#### DEBIAN
`--Dicon`       Path to a single folder where icons are stored.
                To be properly recognized, icons filename must contain `YYxYY`,
                where `YY` is the resolution of the icon.
                SVG files are recognized if suffixed with `.svg`.
                Other files will be ignored.  
`--Demail`      Set the maintainer’s email.  
`--Dauthor`     Set the maintainer’s name.  
`--Dpkg`        Set the name of the package and the command that will be used to launch your game.
                By default, it is the name of your project converted to lowercase,
                with eventual spaces replaced by dashes.  
`--Dversion`    Set the version of your package.  

#### ANDROID
Note that every argument passed to the options should be alphanumerical,
with eventual underscores (i.e. [a-zA-Z0-9\_]), otherwise you'll get errors.  
`--Aicon`       Path to a single folder where icons are stored.
                The script will first look up for filename that contains
                `42x42`, `72x72`, `96x96` or `144x144`.
                It will then search the icon directory for subdirectories like
                `drawable-mdpi`, `drawable-hdpi`, `drawable-xhdpi` and `drawable-xxhdpi`
                to find an `ic_launcher.png` image.  
                OUYA icon (size `732x412`, or `drawable-xhdpi/ouya_icon.png`) is supported.  
`--Aactivity`   The name of the class that extends GameActivity.
                By default it is the name of the project with ‘Activity’ appended,
                eventual spaces and dashes replaced by underscores.  
`--Aauthor`     Set the maintainer’s name.
                It must be only alphanumerical characters, with eventual underscores.  
`--Apkg`        Set the name of the package.
                By default, it is the name of your project, with eventual spaces replaced by underscores.  
`--Aversion`    Set the version of your package.  
`--Aupdate`     Update the love-android-sdl2.git repository used in the cache.  

#### OTHERS
`--clean`       Clean the cache located in `~/.cache/love-release`.
                One can replace the Love files there.  

#### MODULES
The script is modular.
Each different platform is handled by a subscript stored in `scripts`.
If you’d like to add the support of another platform,
or write your own build script, see `scripts/example.sh`.

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

