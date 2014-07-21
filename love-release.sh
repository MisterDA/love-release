#!/bin/bash

## Edit this if you want to use another Löve version.
LOVE_VERSION=0.9.1


## Short help ##
function short_help()
{
echo "Usage: love-release.sh [options...] [files...]
Options:
 -h, --help  Prints short or long help
 -d    Create a deb package
 -l    Create a plain Love file
 -m    Create a MacOS application
 -w,   Create a Windows application
    -w32  Create a Windows x86 application
    -w64  Create a Windows x64 application
 -n    Set the projects name
 -r    Set the release directory
 -u    Set the company name
 -v    Set the Love version
"
}

## Long help ##
function long_help()
{
echo "
.TH LOVE-RELEASE.SH 1
.SH NAME
love-release.sh \- Bash script to generate Love 2D game releases
.SH SYNOPSIS
.B love\-release.sh
[\fB\-dlmw\fR] [\fB\-n\fR \fIproject_name\fR] [\fB\-r\fR \fIrelease_dir\fR]
[\fB\-u\fR \fIcompany_name\fR] [\fB\-v\fR \fIlove_version\fR] [\fIFILES...\fR]
.SH DESCRIPTION
.B love-release.sh
can be used to generate Love 2D game applications
and get over the fastidious zipping commands you had to do.
.PP
The script fully supports Windows, MacOS either on x86 or x64,
and Debian packages.
It needs an Internet connection to download Love files,
and relies on \fBcurl\fR, \fBzip\fR and \fBunzip\fR commands.
To set the default Love version to use,
you can edit the very beginning of the script.
If \fBlua\fR and a \fIconf.lua\fR file are found,
it will automatically detect which version your project uses.
If a \fIProjectName.icns\fR file is provided,
the script will use it to set the game icon on MacOS.
If a \fIProjectName.ico\fR file is provided, and that \fBWine\fR
and \fBResource Hacker\fR are installed, the script will use them
to set the game icon on Windows.
.SH OPTIONS
.TP
.B \-h
Print a short help
.TP
.B \-\-help
Print this longer help
.SH OPERATING SYSTEMS
.TP
.B \-d
Create a deb package. Aimed at Debian and Ubuntu derivatives.
In order to create a Debian package, you must provide more informations about it.
See the DEBIAN section below.
.TP
.B \-l
Create a plain Love file. It is just a zip of your sources, renamed in \fI*.love\fR.
Mostly aimed at Linux players or developers and the most common distribution process.
.TP
.B \-m
Create MacOS application.
Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
If you are targeting one of these, your project must be developed with Love 0.8.0 or lower.
Depending on the Love version used, the script will choose which one,
between x64 only or Universal Build to create.
.TP
.BR \-w \", \" \-w32 \", \" \-w64
Create Windows application.
Starting with Love 0.8.0, a release is specially available for Windows x64.
If you are targeting one of these, your project must be developed with Love 0.8.0 or newer.
Remember that x86 is always backwards compatible with x64.
Depending on the Love version used, the script will choose which one,
between x64 and x86 or x86 only to create.
.br
.B \-w32
Create Windows x86 executable only.
.br
.B \-w64
Create Windows x64 executable only.
.SH PROJECT OPTIONS
.TP
.B \-n \fIproject-name\fR
Set the projects name. By default, the name of the current directory is used.
.TP
.B \-r \fIrelease-dir\fR
Set the release directory. By default, a subdirectory called releases is created.
.TP
.B \-u \fIcompany\fR
Set the company name. Provide it for MacOS CFBundleIdentifier.
.TP
.B \-v \fIversion\fR
Love version. Default is 0.9.1.
Starting with Love 0.8.0, a release is specially available for Windows x64.
Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
.SH DEBIAN
.TP
.B \-\-description \fIdescription\fR
Set the description of your project.
.TP
.B \-\-homepage \fIpage\fR
Set the homepage of your project.
.TP
.B \-\-maintainer-email \fIemail\fR
Set the maintainer's email.
.TP
.B \-\-maintainer\-name \fIname\fR
Set the maintainer's name. The company name is used by default.
.TP
.B \-\-package-name \fIname\fR
Set the name of the package and the command that will be use to launch your game.
By default, it is the name of your project converted to lowercase,
with eventual spaces replaced by dashes.
.TP
.B \-\-version \fIversion\fR
Set the version of your package.
.SH OTHERS
.TP
.B \-\-refresh
Refresh the cache located in \fI~/.cache/love-release\fR.
One can replace the Love files there.
.TP
.B \-\-debug
Dump the scripts variables without making releases.
.SH ICONS
The script doesn’t yet handle the process of creating icons,
but if provided it can use them.
.br
If you want to create MacOS icons (\fI.icns\fR), and you are
running MacOS, then check \fIiconutil\fR. If you are running GNU/Linux,
then check \fIlibicns\fR.
.br
If you want to create Windows icons (\fI.ico\fR),
you can use \fIicoutils\fR to create the icon,
then Wine and Resource Hacker to set the icon.
This last step can be automatically done,
assuming Wine and Resource Hacker are installed.
.br
If you want to add icons in the debian package,
open it and put the icons in \fI/usr/share/icons/hicolor/YYxYY/apps/\fR,
where YY is the width of the icon.
You also have to edit the line \"Icon=love\" in
\fI/usr/share/applications/yourgame.desktop\fR to match the icon's name.
See \fIhttps://developer.gnome.org/integration-guide/stable/basic-integration.html.en\fR
for more informations.
.SH SEE ALSO
.I https://www.love2d.org
.br
.I https://www.love2d.org/wiki/Game_Distribution
.br
.I https://www.github.org/MisterDA/love-release
" | man /dev/stdin
}


## Test if requirements are installed ##
command -v curl  >/dev/null 2>&1 || { echo "curl is not installed. Aborting." >&2; exit 1; }
command -v zip   >/dev/null 2>&1 || { echo "zip is not installed. Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is not installed. Aborting." >&2; exit 1; }

FOUND_LUA=true
command -v lua   >/dev/null 2>&1 || { FOUND_LUA=false; }


## Parsing function ##
function getoptex()
{
  let $# || return 1
  local optlist="${1#;}"
  let OPTIND || OPTIND=1
  [ $OPTIND -lt $# ] || return 1
  shift $OPTIND
  if [ "$1" != "-" ] && [ "$1" != "${1#-}" ]
  then OPTIND=$[OPTIND+1]; if [ "$1" != "--" ]
  then
    local o
    o="-${1#-$OPTOFS}"
    for opt in ${optlist#;}
    do
      OPTOPT="${opt%[;.:]}"
      unset OPTARG
      local opttype="${opt##*[^;:.]}"
      [ -z "$opttype" ] && opttype=";"
      if [ ${#OPTOPT} -gt 1 ]
      then # long-named option
        case $o in
          "--$OPTOPT")
            if [ "$opttype" != ":" ]; then return 0; fi
            OPTARG="$2"
            if [ -z "$OPTARG" ];
            then # error: must have an argument
              let OPTERR && echo "$0: error: $OPTOPT must have an argument" >&2
              exit
              # OPTARG="$OPTOPT";
              # OPTOPT="?"
              return 1;
            fi
            OPTIND=$[OPTIND+1] # skip option's argument
            return 0
          ;;
          "--$OPTOPT="*)
            if [ "$opttype" = ";" ];
            then  # error: must not have arguments
              let OPTERR && echo "$0: error: $OPTOPT must not have arguments" >&2
              exit
              # OPTARG="$OPTOPT"
              # OPTOPT="?"
              return 1
            fi
            OPTARG=${o#"--$OPTOPT="}
            return 0
          ;;
        esac
      else # short-named option
        case "$o" in
          "-$OPTOPT")
            unset OPTOFS
            [ "$opttype" != ":" ] && return 0
            OPTARG="$2"
            if [ -z "$OPTARG" ]
            then
              echo "$0: error: -$OPTOPT must have an argument" >&2
              exit
              # OPTARG="$OPTOPT"
              # OPTOPT="?"
              return 1
            fi
            OPTIND=$[OPTIND+1] # skip option's argument
            return 0
          ;;
          "-$OPTOPT"*)
            if [ "$opttype" = ";" ]
            then # an option with no argument is in a chain of options
              OPTOFS="$OPTOFS?" # move to the next option in the chain
              OPTIND=$[OPTIND-1] # the chain still has other options
              return 0
            else
              unset OPTOFS
              OPTARG="${o#-$OPTOPT}"
              return 0
            fi
          ;;
        esac
      fi
    done
    echo "$0: error: invalid option: $o"
    exit
  fi; fi
  OPTOPT="?"
  unset OPTARG
  return 1
}

float_test() {
    a=$(echo | awk 'END { exit ( !( '"$1"')); }' && echo "true")
    if [ "$a" != "true" ]; then
        a=false
    fi
    echo $a
}


## Set defaults ##
RELEASE_LOVE=false
RELEASE_DEB=false
RELEASE_OSX=false
RELEASE_WIN_32=false
RELEASE_WIN_64=false
RELEASE_APK=false

if [ "$FOUND_LUA" = true ] && [ -f "conf.lua" ]; then
    LOVE_VERSION_AUTO=$(lua -e 'f = loadfile("conf.lua"); t, love = {window = {}, modules = {}}, {}; f(); love.conf(t); t.version = t.version or ""; print(t.version)')
else
    LOVE_VERSION_AUTO=$(grep -Eo -m 1 "t.version = \"[0-9]+.[0-9]+.[0-9]+\"" conf.lua 2> /dev/null |  grep -Eo "[0-9]+.[0-9]+.[0-9]+")
fi
if [ -n "$LOVE_VERSION_AUTO" ]; then
  LOVE_VERSION=$LOVE_VERSION_AUTO
fi
LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
LOVE_GT_080=$(float_test "$LOVE_VERSION_MAJOR >= 0.8")
LOVE_GT_090=$(float_test "$LOVE_VERSION_MAJOR >= 0.9")

PROJECT_FILES=
PROJECT_NAME=${PWD##/*/}
PACKAGE_NAME=${PROJECT_NAME,,}; PACKAGE_NAME=${PACKAGE_NAME// /-}
PROJECT_VERSION=
PROJECT_HOMEPAGE=
PROJECT_DESCRIPTION=
COMPANY_NAME=love2d
MAINTAINER_NAME=$COMPANY_NAME
MAINTAINER_EMAIL=
RELEASE_DIR="$PWD"/releases

DEBUG=false
CACHE_DIR=~/.cache/love-release
EXCLUDE_FILES=$(/bin/ls -A | grep "^[.]" | tr '\n' ' ')


## Debug function ##
function debug()
{
echo "DEBUG=$DEBUG
RELEASE_LOVE=$RELEASE_LOVE
RELEASE_DEB=$RELEASE_DEB
RELEASE_OSX=$RELEASE_OSX
RELEASE_WIN_32=$RELEASE_WIN_32
RELEASE_WIN_64=$RELEASE_WIN_64
RELEASE_APK=$RELEASE_APK
LOVE_VERSION=$LOVE_VERSION
LOVE_VERSION_MAJOR=$LOVE_VERSION_MAJOR
LOVE_VERSION_AUTO=$LOVE_VERSION_AUTO
LOVE_GT_080=$LOVE_GT_080
LOVE_GT_090=$LOVE_GT_090
PROJECT_FILES=$PROJECT_FILES
PROJECT_NAME=$PROJECT_NAME
PACKAGE_NAME=$PACKAGE_NAME
PROJECT_VERSION=$PROJECT_VERSION
PROJECT_HOMEPAGE=$PROJECT_HOMEPAGE
PROJECT_DESCRIPTION=$PROJECT_DESCRIPTION
COMPANY_NAME=$COMPANY_NAME
MAINTAINER_NAME=$MAINTAINER_NAME
MAINTAINER_EMAIL=$MAINTAINER_EMAIL
RELEASE_DIR=$RELEASE_DIR
CACHE_DIR=$CACHE_DIR
PROJECT_ICO=$PROJECT_ICO
PROJECT_ICNS=$PROJECT_ICNS
EXCLUDE_FILES=$EXCLUDE_FILES
"
}


## Parsing options ##
while getoptex "a; h; d; l; m; w. n: r: u: v: version: maintainer-name: maintainer-email: homepage: description: package-name: debug help refresh" "$@"
do
  if [ "$OPTOPT" = "h" ]; then
    short_help
    exit
  elif [ "$OPTOPT" = "a" ]; then
    RELEASE_APK=true
  elif [ "$OPTOPT" = "d" ]; then
    RELEASE_DEB=true
  elif [ "$OPTOPT" = "l" ]; then
    RELEASE_LOVE=true
  elif [ "$OPTOPT" = "m" ]; then
    RELEASE_OSX=true
  elif [ "$OPTOPT" = "w" ]; then
    if [ "$OPTARG" = "32" ]; then
      RELEASE_WIN_32=true
    elif [ "$OPTARG" = "64" ]; then
      RELEASE_WIN_64=true
    else
      RELEASE_WIN_32=true
      RELEASE_WIN_64=true
    fi
  elif [ "$OPTOPT" = "n" ]; then
    PROJECT_NAME=$OPTARG
  elif [ "$OPTOPT" = "r" ]; then
    RELEASE_DIR=$OPTARG
  elif [ "$OPTOPT" = "u" ]; then
    COMPANY_NAME=$OPTARG
  elif [ "$OPTOPT" = "v" ]; then
    LOVE_VERSION=$OPTARG
    LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
    LOVE_GT_080=$(float_test "$LOVE_VERSION_MAJOR >= 0.8")
    LOVE_GT_090=$(float_test "$LOVE_VERSION_MAJOR >= 0.9")
  elif [ "$OPTOPT" = "version" ]; then
    PROJECT_VERSION=$OPTARG
  elif [ "$OPTOPT" = "homepage" ]; then
    PROJECT_HOMEPAGE=$OPTARG
  elif [ "$OPTOPT" = "description" ]; then
    PROJECT_DESCRIPTION=$OPTARG
  elif [ "$OPTOPT" = "maintainer-name" ]; then
    MAINTAINER_NAME=$OPTARG
  elif [ "$OPTOPT" = "maintainer-email" ]; then
    MAINTAINER_EMAIL=$OPTARG
  elif [ "$OPTOPT" = "package-name" ]; then
    PACKAGE_NAME=$OPTARG
  elif [ "$OPTOPT" = "debug" ]; then
    DEBUG=true
  elif [ "$OPTOPT" = "help" ]; then
    long_help
    exit
  elif [ "$OPTOPT" = "refresh" ]; then
    rm -rf $CACHE_DIR
  fi
done
shift $[OPTIND-1]
for file in "$@"
do
  PROJECT_FILES="$PROJECT_FILES $file"
done
if [ "$RELEASE_LOVE" = false ] && [ "$RELEASE_DEB" = false ] && [ "$RELEASE_OSX" = false ] && [ "$RELEASE_WIN_32" = false ] && [ "$RELEASE_WIN_64" = false ] && [ "$RELEASE_APK" = false ]; then
  RELEASE_LOVE=true
  RELEASE_DEB=true
  RELEASE_OSX=true
  RELEASE_WIN_32=true
  RELEASE_WIN_64=true
fi
if [ "$RELEASE_APK" = true ]; then
  RELEASE_LOVE=false
  RELEASE_DEB=false
  RELEASE_OSX=false
  RELEASE_WIN_32=false
  RELEASE_WIN_64=false
fi
MAIN_RELEASE_DIR=${RELEASE_DIR##/*/}
RELEASE_DIR="$RELEASE_DIR"/$LOVE_VERSION
CACHE_DIR=$CACHE_DIR/$LOVE_VERSION
if [ -f "$PWD"/"$PROJECT_NAME".icns ]; then
  PROJECT_ICNS="$PWD"/"$PROJECT_NAME".icns
else
  PROJECT_ICNS=
fi
if [ -f "$PWD"/"$PROJECT_NAME".ico ]; then
  PROJECT_ICO="$PWD"/"$PROJECT_NAME".ico
else
  PROJECT_ICO=
fi
if [ -z "$PROJECT_VERSION" ]; then
  PROJECT_VERSION=1
fi


## Debug log ##
if [ "$DEBUG" = true ]; then
  debug
  exit
fi


echo "Generating "$PROJECT_NAME" with Love $LOVE_VERSION..."


## Zipping ##
mkdir -p "$RELEASE_DIR" $CACHE_DIR
rm -rf "$RELEASE_DIR"/"$PROJECT_NAME".love 2> /dev/null
if [ -z "$PROJECT_FILES" ]; then
  zip -9 -r "$RELEASE_DIR"/"$PROJECT_NAME".love -x $0 "$MAIN_RELEASE_DIR"/\* ${PROJECT_ICNS##/*/} ${PROJECT_ICO##/*/} $EXCLUDE_FILES @ *
else
  zip -9 -r "$RELEASE_DIR"/"$PROJECT_NAME".love -x $0 "$MAIN_RELEASE_DIR"/\* ${PROJECT_ICNS##/*/} ${PROJECT_ICO##/*/} $EXCLUDE_FILES @ $PROJECT_FILES
fi
cd "$RELEASE_DIR"


## Windows 32-bits ##
if [ "$RELEASE_WIN_32" = true ]; then
  if [ "$LOVE_GT_090" = true ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win32.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win32.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win32.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win32.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win32.zip ./
    fi
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win-x86.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./love-$LOVE_VERSION-win32.zip
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x86.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./love-$LOVE_VERSION-win32.zip
    fi
  fi
  unzip -qq love-$LOVE_VERSION-win32.zip
  rm -rf "$PROJECT_NAME"-win32.zip 2> /dev/null
  wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Resource\ Hacker/ResHacker.exe -addoverwrite "love-$LOVE_VERSION-win32/love.exe,love-$LOVE_VERSION-win32/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0"
  cat love-$LOVE_VERSION-win32/love.exe "$PROJECT_NAME".love > love-$LOVE_VERSION-win32/"$PROJECT_NAME".exe
  rm love-$LOVE_VERSION-win32/love.exe
  zip -9 -qr "$PROJECT_NAME"-win32.zip love-$LOVE_VERSION-win32
  rm -rf love-$LOVE_VERSION-win32.zip love-$LOVE_VERSION-win32
fi

## Windows 64-bits ##
if [ "$RELEASE_WIN_64" = true ] && [ "$LOVE_GT_080" = true ]; then
  if [ "$LOVE_GT_090" = true ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win64.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win64.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win64.zip ./
    fi
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win-x64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ./love-$LOVE_VERSION-win64.zip
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x64.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ./love-$LOVE_VERSION-win64.zip
    fi
  fi
  unzip -qq love-$LOVE_VERSION-win64.zip
  rm -rf "$PROJECT_NAME"-win64.zip 2> /dev/null
  wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Resource\ Hacker/ResHacker.exe -addoverwrite "love-$LOVE_VERSION-win64/love.exe,love-$LOVE_VERSION-win64/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0"
  cat love-$LOVE_VERSION-win64/love.exe "$PROJECT_NAME".love > love-$LOVE_VERSION-win64/"$PROJECT_NAME".exe
  rm love-$LOVE_VERSION-win64/love.exe
  zip -9 -qr "$PROJECT_NAME"-win64.zip love-$LOVE_VERSION-win64
  rm -rf love-$LOVE_VERSION-win64.zip love-$LOVE_VERSION-win64
fi

## MacOS ##
if [ "$RELEASE_OSX" = true ]; then

  ## MacOS 64-bits ##
  if [ "$LOVE_GT_090" = true ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-x64.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-x64.zip
    rm -rf "$PROJECT_NAME"-macosx-x64.zip 2> /dev/null
    mv love.app "$PROJECT_NAME".app
    cp "$PROJECT_NAME".love "$PROJECT_NAME".app/Contents/Resources
    cp "$PROJECT_ICNS" "$PROJECT_NAME".app/Contents/Resources 2> /dev/null
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>BuildMachineOSBuild</key>
    <string>13A603</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeIconFile</key>
            <string>LoveDocument.icns</string>
            <key>CFBundleTypeName</key>
            <string>LÖVE Project</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>org.love2d.love-game</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>CFBundleTypeOSTypes</key>
            <array>
                <string>fold</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>None</string>
        </dict>
    </array>
    <key>CFBundleExecutable</key>
    <string>love</string>
    <key>CFBundleIconFile</key>
    <string>${PROJECT_ICNS##/*/}</string>
    <key>CFBundleIdentifier</key>
    <string>org.$COMPANY_NAME."$PROJECT_NAME"</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>"$PROJECT_NAME"</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$LOVE_VERSION</string>
    <key>CFBundleSignature</key>
    <string>LoVe</string>
    <key>DTCompiler</key>
    <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>DTPlatformBuild</key>
    <string>5A3005</string>
    <key>DTPlatformVersion</key>
    <string>GM</string>
    <key>DTSDKBuild</key>
    <string>13A595</string>
    <key>DTSDKName</key>
    <string>macosx10.9</string>
    <key>DTXcode</key>
    <string>0502</string>
    <key>DTXcodeBuild</key>
    <string>5A3005</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.games</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2006-2013 LÖVE Development Team</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>" > "$PROJECT_NAME".app/Contents/Info.plist
    zip -9 -qr "$PROJECT_NAME"-macosx-x64.zip "$PROJECT_NAME".app
    rm -rf love-$LOVE_VERSION-macosx-x64.zip "$PROJECT_NAME".app __MACOSX

  ## MacOS 32-bits ##
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-ub.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-ub.zip
    rm -rf "$PROJECT_NAME"-macosx-ub.zip 2> /dev/null
    mv love.app "$PROJECT_NAME".app
    cp "$PROJECT_NAME".love "$PROJECT_NAME".app/Contents/Resources
    cp "$PROJECT_ICNS" "$PROJECT_NAME".app/Contents/Resources 2> /dev/null
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>BuildMachineOSBuild</key>
    <string>11D50b</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeIconFile</key>
            <string>LoveDocument.icns</string>
            <key>CFBundleTypeName</key>
            <string>LÖVE Project</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>org.love2d.love-game</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>CFBundleTypeOSTypes</key>
            <array>
                <string>fold</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>None</string>
        </dict>
    </array>
    <key>CFBundleExecutable</key>
    <string>love</string>
    <key>CFBundleIconFile</key>
    <string>${PROJECT_ICNS##/*/}</string>
    <key>CFBundleIdentifier</key>
    <string>com.$COMPANY_NAME."$PROJECT_NAME"</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>"$PROJECT_NAME"</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$LOVE_VERSION</string>
    <key>CFBundleSignature</key>
    <string>LoVe</string>
    <key>DTCompiler</key>
    <string></string>
    <key>DTPlatformBuild</key>x
    <string>4E2002</string>
    <key>DTPlatformVersion</key>
    <string>GM</string>
    <key>DTSDKBuild</key>
    <string>11D50a</string>
    <key>DTSDKName</key>
    <string>macosx10.7</string>
    <key>DTXcode</key>
    <string>0432</string>
    <key>DTXcodeBuild</key>
    <string>4E2002</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2006-2012 LÖVE Development Team</string>
    <key>NSMainNibFile</key>
    <string>SDLMain</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>" > "$PROJECT_NAME".app/Contents/Info.plist
    zip -9 -qr "$PROJECT_NAME"-macosx-ub.zip "$PROJECT_NAME".app
    rm -rf love-$LOVE_VERSION-macosx-ub.zip "$PROJECT_NAME".app __MACOSX
  fi
fi

## Debian package ##
if [ "$RELEASE_DEB" = true ]; then
  if [ -z "$PROJECT_VERSION" ] || [ -z "$PROJECT_HOMEPAGE" ] || [ -z "$PROJECT_DESCRIPTION" ] || [ -z "$MAINTAINER_NAME" ] || [ -z "$MAINTAINER_EMAIL" ]; then
    echo "Could not build a Debian package. Missing informations."
  else
    TEMP=`mktemp -d`
    mkdir -p $TEMP/DEBIAN

    echo "Package: $PACKAGE_NAME"    >  $TEMP/DEBIAN/control
    echo "Version: $PROJECT_VERSION" >> $TEMP/DEBIAN/control
    echo "Architecture: all"         >> $TEMP/DEBIAN/control
    echo "Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>" >> $TEMP/DEBIAN/control
    echo "Installed-Size: $(echo "$(stat -c %s "$PROJECT_NAME".love) / 1024" | bc)" >> $TEMP/DEBIAN/control
    echo "Depends: love (>= $LOVE_VERSION)"   >> $TEMP/DEBIAN/control
    echo "Priority: extra"                    >> $TEMP/DEBIAN/control
    echo "Homepage: $PROJECT_HOMEPAGE"        >> $TEMP/DEBIAN/control
    echo "Description: $PROJECT_DESCRIPTION"  >> $TEMP/DEBIAN/control
    chmod 0644 $TEMP/DEBIAN/control

    DESKTOP=$TEMP/usr/share/applications/"$PACKAGE_NAME".desktop
    mkdir -p $TEMP/usr/share/applications
    echo "[Desktop Entry]"              > $DESKTOP
    echo "Name=$PROJECT_NAME"           >> $DESKTOP
    echo "Comment=$PROJECT_DESCRIPTION" >> $DESKTOP
    echo "Exec=$PACKAGE_NAME"           >> $DESKTOP
    echo "Type=Application"             >> $DESKTOP
    echo "Categories=Game;"             >> $DESKTOP
    echo "Icon=love"                    >> $DESKTOP
    chmod 0644 $DESKTOP

    PACKAGE_DIR=/usr/share/games/"$PACKAGE_NAME"/
    PACKAGE_LOC=$PACKAGE_NAME-$PROJECT_VERSION.love

    mkdir -p $TEMP"$PACKAGE_DIR"
    cp "$PROJECT_NAME".love $TEMP"$PACKAGE_DIR""$PACKAGE_LOC"
    chmod 0644 $TEMP"$PACKAGE_DIR""$PACKAGE_LOC"

    BIN_LOC=/usr/bin/
    mkdir -p $TEMP$BIN_LOC
    echo "#!/usr/bin/env bash" >  $TEMP$BIN_LOC"$PACKAGE_NAME"
    echo "set -e"              >> $TEMP$BIN_LOC"$PACKAGE_NAME"
    echo "love $PACKAGE_DIR$PACKAGE_LOC" >> $TEMP$BIN_LOC"$PACKAGE_NAME"
    chmod 0755 $TEMP$BIN_LOC"$PACKAGE_NAME"

    cd $TEMP
    for line in $(find usr/ -type f); do
      md5sum $line >> $TEMP/DEBIAN/md5sums
    done
    chmod 0644 $TEMP/DEBIAN/md5sums

    for line in $(find usr/ -type d); do
      chmod 0755 $line
    done

    fakeroot dpkg-deb -b $TEMP "$RELEASE_DIR"/"$PACKAGE_NAME"-"$PROJECT_VERSION"_all.deb
    cd "$RELEASE_DIR"
    rm -rf $TEMP
  fi
fi

## Android apk ##
if [ "$RELEASE_APK" = true ]; then
  LOVE_ANDROID_DIR="$CACHE_DIR"/love-android-sdl2
  if [ -d "$LOVE_ANDROID_DIR" ]; then
    cd "$LOVE_ANDROID_DIR"
    git checkout -- .
    rm -rf src/com bin gen
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})
    if [ $LOCAL = $REMOTE ]; then
      :
    elif [ $LOCAL = $BASE ]; then
      git pull
      ndk-build --jobs $(( $(nproc) + 1))
    fi
    cd "$RELEASE_DIR"
  else
    cd "$CACHE_DIR"
    git clone https://bitbucket.org/MartinFelis/love-android-sdl2.git
    cd "$LOVE_ANDROID_DIR"
    ndk-build --jobs $(( $(nproc) + 1))
    cd "$RELEASE_DIR"
  fi

  MAINTAINER_USERNAME=${MAINTAINER_NAME// /_}
  ACTIVITY=${PROJECT_NAME// /_}Activity
  ANDROID_VERSION=$(grep -Eo -m 1 "[0-9]+.[0-9]+.[0-9]+[a-z]*" "$LOVE_ANDROID_DIR"/AndroidManifest.xml)
  ANDROID_LOVE_VERSION=$(echo "$ANDROID_VERSION" | grep -Eo "[0-9]+.[0-9]+.[0-9]+")
  if [ "$LOVE_VERSION" != "$ANDROID_LOVE_VERSION" ]; then
    echo "Love version ($LOVE_VERSION) differs from love-android-sdl2 version ($ANDROID_LOVE_VERSION). Could not create package."
  else
    mkdir -p "$LOVE_ANDROID_DIR"/assets
    cp "$PROJECT_NAME".love "$LOVE_ANDROID_DIR"/assets/game.love
    cd "$LOVE_ANDROID_DIR"
    sed -i "s/org.love2d.android/com.${MAINTAINER_USERNAME}.${PACKAGE_NAME}/" AndroidManifest.xml
    sed -i "s/$ANDROID_VERSION/${ANDROID_VERSION}-${PACKAGE_NAME}-v${PROJECT_VERSION}/" AndroidManifest.xml
    sed -i "0,/LÖVE for Android/s//$PROJECT_NAME $PROJECT_VERSION/" AndroidManifest.xml
    sed -i "s/LÖVE for Android/$PROJECT_NAME/" AndroidManifest.xml
    sed -i "s/GameActivity/$ACTIVITY/" AndroidManifest.xml

    mkdir -p src/com/$MAINTAINER_USERNAME/$PACKAGE_NAME
echo "package com.${MAINTAINER_USERNAME}.${PACKAGE_NAME};
import org.love2d.android.GameActivity;

public class $ACTIVITY extends GameActivity {}
" > src/com/$MAINTAINER_USERNAME/$PACKAGE_NAME/${ACTIVITY}.java

    ant debug
    cp bin/love_android_sdl2-debug.apk "$RELEASE_DIR"
    cd "$RELEASE_DIR"
  fi
fi

## Love file ##
if [ "$RELEASE_LOVE" = false ]; then
  rm "$PROJECT_NAME".love
fi

echo "Done !"
