#!/bin/bash

## Edit this if you want to use another Löve version.
LOVE_VERSION=0.9.1


## Short help ##
function short_help()
{
echo "Usage: love-release.sh [options...] [files...]
Options:
 -h, --help  Prints short or long help
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
echo "NAME
     love-release.sh -- Bash script to generate Love 2D game releases
SYNOPSIS
     love-release.sh [-lmw] [-n project_name] [-r release_dir] [-u company_name] [-v love_version] [FILES...]

DESCRIPTION
     You can use love-release.sh to generate Love 2D game applications and get over the fastidious zipping commands you had to do.
     The script fully supports Windows, MacOS either on x86 or x64.
     It needs an Internet connection to download Love files, and relies on curl, zip and unzip commands.
     To set the default Love version to use, you can edit the very beginning of the script.
     If lua and a conf.lua file are found, it will automatically detect which version your project uses.
     If a ProjectName.icns file is provided, the script will use it to set the game icon on MacOS.

OPTIONS
     -h     Print a short help
     --help Print this longer help

  OPERATING SYSTEMS
     -l     Create a plain Love file. It is just a zip of your sources, renamed in *.love.
            Mostly aimed at Linux players or developers and the most common distribution process.

     -m     Create MacOS application.
            Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.
            If you are targeting one of these, your project must be developed with Love 0.8.0 or lower.
            Depending on the Love version used, the script will choose which one, between x64 only or Universal Build to create.

     -w     Create Windows application.
            Starting with Love 0.8.0, a release is specially available for Windows x64.
            If you are targeting one of these, your project must be developed with Love 0.8.0 or newer.
            Remember that x86 is always backwards compatible with x64.
            Depending on the Love version used, the script will choose which one, between x64 and x86 or x86 only to create.
       -w32  Create Windows x86 executable only
       -w64  Create Windows x64 executable only

  PROJECT OPTIONS
     -n     Set the projects name. By default, the name of the current directory is used.

     -r     Set the release directory. By default, a subdirectory called releases is created.

     -u     Set the company name. Provide it for MacOS CFBundleIdentifier.

     -v     Love version. Default is 0.9.1.
            Starting with Love 0.8.0, a release is specially available for Windows x64.
            Starting with Love 0.9.0, Love no longer supports old x86 Macintosh.

  OTHERS
     --refresh   Refresh the cache located in ~/.cache/love-release. One can replace the Love files there.
     --debug     Dump the scripts variables without making releases.

SEE ALSO
     https://www.love2d.org
     https://www.love2d.org/wiki/Game_Distribution
     https://www.github.org/MisterDA/love-release
"
}


## Test if requirements are installed ##
command -v curl  >/dev/null 2>&1 || { echo "curl is not installed. Aborting." >&2; exit 1; }
command -v zip   >/dev/null 2>&1 || { echo "zip is not installed. Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is not installed. Aborting." >&2; exit 1; }

command -v lua   >/dev/null 2>&1 || { FOUND_LUA=true; }


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


## Set defaults ##
RELEASE_LOVE=false
RELEASE_OSX=false
RELEASE_WIN_32=false
RELEASE_WIN_64=false

if [ "$FOUND_LUA" = true ]; then
    LOVE_VERSION_AUTO=$(lua -e 'f = loadfile("conf.lua"); t, love = {window = {}, modules = {}}, {}; f(); love.conf(t); print(t.version)')
else
    LOVE_VERSION_AUTO=$(grep -Eo -m 1 "t.version = \"[0-9]+.[0-9]+.[0-9]+\"" conf.lua 2> /dev/null |  grep -Eo "[0-9]+.[0-9]+.[0-9]")
fi
if [ -n "$LOVE_VERSION_AUTO" ]; then
  LOVE_VERSION=$LOVE_VERSION_AUTO
fi
LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
LOVE_GT_080=$(echo "$LOVE_VERSION_MAJOR>=0.8" | bc)
LOVE_GT_090=$(echo "$LOVE_VERSION_MAJOR>=0.9" | bc)

PROJECT_FILES=
PROJECT_NAME=${PWD##/*/}
COMPANY_NAME=love2d
RELEASE_DIR=$PWD/releases

DEBUG=false
CACHE_DIR=~/.cache/love-release
EXCLUDE_FILES=$(/bin/ls -A | grep "^[.]" | tr '\n' ' ')


## Debug function ##
function debug()
{
echo "DEBUG=$DEBUG
RELEASE_LOVE=$RELEASE_LOVE
RELEASE_OSX=$RELEASE_OSX
RELEASE_WIN_32=$RELEASE_WIN_32
RELEASE_WIN_64=$RELEASE_WIN_64
LOVE_VERSION=$LOVE_VERSION
LOVE_VERSION_MAJOR=$LOVE_VERSION_MAJOR
LOVE_VERSION_AUTO=$LOVE_VERSION_AUTO
LOVE_GT_080=$LOVE_GT_080
LOVE_GT_090=$LOVE_GT_090
PROJECT_FILES=$PROJECT_FILES
PROJECT_NAME=$PROJECT_NAME
COMPANY_NAME=$COMPANY_NAME
RELEASE_DIR=$RELEASE_DIR
CACHE_DIR=$CACHE_DIR
PROJECT_ICNS=$PROJECT_ICNS
EXCLUDE_FILES=$EXCLUDE_FILES
"
}


## Parsing options ##
while getoptex "h; l; m; w. n: r: u: v: debug help refresh" "$@"
do
  if [ "$OPTOPT" = "h" ]; then
    short_help
    exit
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
    LOVE_GT_080=$(echo "$LOVE_VERSION_MAJOR>=0.8" | bc)
    LOVE_GT_090=$(echo "$LOVE_VERSION_MAJOR>=0.9" | bc)
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
if [ "$RELEASE_LOVE" = false ] && [ "$RELEASE_OSX" = false ] && [ "$RELEASE_WIN_32" = false ] && [ "$RELEASE_WIN_64" = false ]; then
  RELEASE_LOVE=true
  RELEASE_OSX=true
  RELEASE_WIN_32=true
  RELEASE_WIN_64=true
fi
MAIN_RELEASE_DIR=${RELEASE_DIR##/*/}
RELEASE_DIR=$RELEASE_DIR/$LOVE_VERSION
CACHE_DIR=$CACHE_DIR/$LOVE_VERSION
if [ -f "$PWD/$PROJECT_NAME.icns" ]; then
    PROJECT_ICNS=$PWD/$PROJECT_NAME.icns
else
    PROJECT_ICNS=
fi


## Debug log ##
if [ "$DEBUG" = true ]; then
  debug
  exit
fi


echo "Generating $PROJECT_NAME with Love $LOVE_VERSION..."


## Zipping ##
mkdir -p $RELEASE_DIR $CACHE_DIR
rm -rf $RELEASE_DIR/$PROJECT_NAME.love 2> /dev/null
if [ -z "$PROJECT_FILES" ]; then
  zip -9 -r $RELEASE_DIR/$PROJECT_NAME.love -x $0 $MAIN_RELEASE_DIR/\* ${PROJECT_ICNS##/*/} $EXCLUDE_FILES @ *
else
  zip -9 -r $RELEASE_DIR/$PROJECT_NAME.love -x $0 $MAIN_RELEASE_DIR/\* ${PROJECT_ICNS##/*/} $EXCLUDE_FILES @ $PROJECT_FILES
fi
cd $RELEASE_DIR


## Windows 32-bits ##
if [ "$RELEASE_WIN_32" = true ]; then
  if [ "$LOVE_GT_090" = "1" ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win32.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win32.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win32.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win32.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win32.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-win32.zip
    rm -rf $PROJECT_NAME-win32.zip 2> /dev/null
    cat love-$LOVE_VERSION-win32/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win32/$PROJECT_NAME.exe
    rm love-$LOVE_VERSION-win32/love.exe
    zip -9 -qr $PROJECT_NAME-win32.zip love-$LOVE_VERSION-win32
    rm -rf love-$LOVE_VERSION-win32.zip love-$LOVE_VERSION-win32
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win-x86.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x86.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-win-x86.zip
    rm -rf $PROJECT_NAME-win-x86.zip 2> /dev/null
    cat love-$LOVE_VERSION-win-x86/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win-x86/$PROJECT_NAME.exe
    rm love-$LOVE_VERSION-win-x86/love.exe
    zip -9 -qr $PROJECT_NAME-win-x86.zip love-$LOVE_VERSION-win-x86
    rm -rf love-$LOVE_VERSION-win-x86.zip love-$LOVE_VERSION-win-x86
  fi
fi

## Windows 64-bits ##
if [ "$RELEASE_WIN_64" = true ] && [ "$LOVE_GT_080" = "1" ]; then
  if [ "$LOVE_GT_090" = "1" ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win64.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win64.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-win64.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-win64.zip
    rm -rf $PROJECT_NAME-win64.zip 2> /dev/null
    cat love-$LOVE_VERSION-win64/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win64/$PROJECT_NAME.exe
    rm love-$LOVE_VERSION-win64/love.exe
    zip -9 -qr $PROJECT_NAME-win64.zip love-$LOVE_VERSION-win64
    rm -rf love-$LOVE_VERSION-win64.zip love-$LOVE_VERSION-win64
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-win-x64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x64.zip
    fi
    unzip -qq love-$LOVE_VERSION-win-x64.zip
    rm -rf $PROJECT_NAME-win-x64.zip 2> /dev/null
    cat love-$LOVE_VERSION-win-x64/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win-x64/$PROJECT_NAME.exe
    rm love-$LOVE_VERSION-win-x64/love.exe
    zip -9 -qr $PROJECT_NAME-win-x64.zip love-$LOVE_VERSION-win-x64
    rm -rf love-$LOVE_VERSION-win-x64.zip love-$LOVE_VERSION-win-x64
  fi
fi

## MacOS ##
if [ "$RELEASE_OSX" = true ]; then

  ## MacOS 64-bits ##
  if [ "$LOVE_GT_090" = "1" ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-x64.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-x64.zip
    rm -rf $PROJECT_NAME-macosx-x64.zip 2> /dev/null
    mv love.app $PROJECT_NAME.app
    cp $PROJECT_NAME.love $PROJECT_NAME.app/Contents/Resources
    cp $PROJECT_ICNS $PROJECT_NAME.app/Contents/Resources 2> /dev/null
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
    <string>org.$COMPANY_NAME.$PROJECT_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
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
</plist>" > $PROJECT_NAME.app/Contents/Info.plist
    zip -9 -qr $PROJECT_NAME-macosx-x64.zip $PROJECT_NAME.app
    rm -rf love-$LOVE_VERSION-macosx-x64.zip $PROJECT_NAME.app

  ## MacOS 32-bits ##
  else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip" ]; then
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    else
      curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-ub.zip
      cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-ub.zip
    rm -rf $PROJECT_NAME-macosx-ub.zip 2> /dev/null
    mv love.app $PROJECT_NAME.app
    cp $PROJECT_NAME.love $PROJECT_NAME.app/Contents/Resources
    cp $PROJECT_ICNS $PROJECT_NAME.app/Contents/Resources 2> /dev/null
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
    <string>com.$COMPANY_NAME.$PROJECT_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
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
</plist>" > $PROJECT_NAME.app/Contents/Info.plist
    zip -9 -qr $PROJECT_NAME-macosx-ub.zip $PROJECT_NAME.app
    rm -rf love-$LOVE_VERSION-macosx-ub.zip $PROJECT_NAME.app
  fi
fi

## Love file ##
if [ "$RELEASE_LOVE" = false ]; then
  rm $PROJECT_NAME.love
fi

echo "Done !"
