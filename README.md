### NAME
`love-release.sh` -- Bash script to generate Love 2D game releases

### SYNOPSIS
`love-release.sh [-lmw] [-n project_name] [-r release_dir] [-u company_name] [-v love_version] [FILES...]`

### DESCRIPTION
You can use love-release.sh to generate Love 2D game applications and get over the fastidious zipping commands you had to do.  
The script fully supports Windows, MacOS either on x86 or x64.  
It needs an Internet connection to download Love files, and relies on curl, zip and unzip commands.  
To set the default Love version to use, you can edit the very beginning of the script.  
If `lua` and a `conf.lua` file are found, it will automatically detect which version your project uses.  
If a `ProjectName.icns` file is provided, the script will use it to set the game icon on MacOS.  
If a `ProjectName.ico` file is provided, and that Wine and Resource Hacker are installed, the script will use them to set the game icon on Windows.

### OPTIONS
`-h`     Print a short help  
`--help` Print this longer help

#### OPERATING SYSTEMS
`-l` Create a plain Love file. It is just a zip of your sources, renamed in \*.love.
     Mostly aimed at Linux players or developers and the most common distribution process.

`-m` Create MacOS application.
     Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
     If you are targeting one of these, your project must be developped with Love 0.8.0 or lower.
     Depending on the Love version used, the script will choose which one, between x64 only or Universal Build to create.

`-w` Create Windows application.
     Starting with Love 0.8.0, a release is specially available for Windows x64.
     If you are targeting one of these, your project must be developed with Love 0.8.0 or newer.
     Remember that x86 is always backwards compatible with x64.
     Depending on the Love version used, the script will choose which one, between x64 and x86 or x86 only to create.  
`-w32`  Create Windows x86 executable only  
`-w64`  Create Windows x64 executable only

#### PROJECT OPTIONS
`-n`  Set the projects name. By default, the name of the current directory is used.

`-r`  Set the release directory. By default, a subdirectory called releases is created.

`-u`  Set the company name. Provide it for MacOS CFBundleIdentifier.

`-v`  Love version. Default is 0.9.1.
      Starting with Love 0.8.0, a release is specially available for Windows x64.
      Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.

#### ICONS
A note on icons:
- if you want to create MacOS icons (.icns), and you are
  - running MacOS, then check [iconutil](https://developer.apple.com/library/mac/documentation/userexperience/conceptual/applehiguidelines/IconsImages/IconsImages.html).
  - running GNU/Linux, then check [libicns](http://icns.sourceforge.net/).
- if you want to create Windows icons (.ico), you can
  - use [icoutils](http://www.nongnu.org/icoutils/) to create the icon,
  - then [Wine](http://www.winehq.org/) and [Resource Hacker](http://www.angusj.com/resourcehacker/) to set the icon.

The script doesn’t yet handle the process of creating icons, but if provided it can use them, assuming Wine and Resource Hacker are installed.

#### OTHERS
`--refresh`   Refresh the cache located in `~/.cache/love-release`. One can replace the Love files there.  
`--debug`     Dump the scripts variables without making releases.

### SEE ALSO
[https://www.love2d.org](https://www.love2d.org)  
[https://www.love2d.org/wiki/Game_Distribution](https://www.love2d.org/wiki/Game_Distribution)  
[https://www.github.org/MisterDA/love-release](https://www.github.org/MisterDA/love-release)
