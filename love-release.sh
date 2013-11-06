#!/bin/bash

HELP="### Generates Love2D Game releases ###

SYNOPSIS
    love-release.sh [OPTIONS] [FILES...]

DESCRIPTION
    You can use love-release.sh to generate Love2D executables for Linux, OS X, Windows (x86 and x86_64), as specified in love2d.org.
    An Internet connection is required. The script uses wget, zip and unzip commands.

    By default, the script generates releases for every system. But if you add options, 
    it will generate releases only for the specified systems.

    A directory (default is './releases') will be created, and filled with the zipped releases:
        'YourGame-win-x86.zip', 'YourGame-win-x64.zip', 'YourGame-osx.zip' and 'YourGame.love'.

OPTIONS
    -h,  print this help

    -l,  generates a .love file
    -m,  generates a Mac OS X app
    -w,  generates Windows x86 and x86_64 executables
         -w32,  generates Windows x86 executable 
         -w64,  generates Windows x86_64 executable
    
    -n,  project's name. By default, the directory's name is used
    -r,  release directory. By default, a subdirectory called 'releases' is created
    -u,  company name. Provide it for OSX CFBundleIdentifier, otherwise USER is used
    -v,  love version. Default is 0.8.0. Prior to it, no special Win64 version is available
    
    --refresh,  refresh the cache located in '~/.cache/love-release'

SEE ALSO
    https://www.love2d.org
    https://www.love2d.org/wiki/Game_Distribution
    https://www.github.org/MisterDA/love-release
"


## Test if requirements are installed ##
command -v wget  >/dev/null 2>&1 || { echo "wget is not installed. Aborting." >&2; exit 1; }
command -v zip   >/dev/null 2>&1 || { echo "zip is not installed. Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is not installed. Aborting." >&2; exit 1; }


## Parsing functions ##
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
            then # error: must have an agrument
              let OPTERR && echo "$0: error: $OPTOPT must have an argument" >&2
              OPTARG="$OPTOPT";
              OPTOPT="?"
              return 1;
            fi
            OPTIND=$[OPTIND+1] # skip option's argument
            return 0
          ;;
          "--$OPTOPT="*)
            if [ "$opttype" = ";" ];
            then  # error: must not have arguments
              let OPTERR && echo "$0: error: $OPTOPT must not have arguments" >&2
              OPTARG="$OPTOPT"
              OPTOPT="?"
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
              OPTARG="$OPTOPT"
              OPTOPT="?"
              return 1
            fi
            OPTIND=$[OPTIND+1] # skip option's argument
            return 0
          ;;
          "-$OPTOPT"*)
            if [ $opttype = ";" ]
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
PROJECT_NAME=${PWD##/*/}
RELEASE_DIR=$PWD/releases
COMPANY_NAME=$USER
LOVE_VERSION=0.8.0
CACHE_DIR=~/.cache/love-release


## Parsing options ##
while getoptex "h; l; m; w. n: r: u: v: refresh" "$@"
do
  if [ $OPTOPT = "h" ]; then # print help
    echo "$HELP"
    exit
  elif [ $OPTOPT = "l" ]; then
    RELEASE_LOVE=true
  elif [ $OPTOPT = "m" ]; then
    RELEASE_OSX=true
  elif [ $OPTOPT = "w" ]; then
    if [ $OPTARG = "32" ]; then
      RELEASE_WIN_32=true
    elif [ $OPTARG = "64" ]; then
      RELEASE_WIN_64=true
    else
      RELEASE_WIN_32=true
      RELEASE_WIN_64=true
    fi
  elif [ $OPTOPT = "n" ]; then
    PROJECT_NAME=$OPTARG
  elif [ $OPTOPT = "r" ]; then
    RELEASE_DIR=$OPTARG
  elif [ $OPTOPT = "u" ]; then
    COMPANY_NAME=$OPTARG
  elif [ $OPTOPT = "v" ]; then
    LOVE_VERSION=$OPTARG
  elif [ $OPTOPT = "refresh" ]; then
    rm -rf $CACHE_DIR/*
  fi
done
shift $[OPTIND-1]
for file in "$@"
do
  PROJECT_FILES="$PROJECT_FILES $file"
done
if [ $RELEASE_LOVE = false ] && [ $RELEASE_OSX = false ] && [ $RELEASE_WIN_32 = false ] && [ $RELEASE_WIN_64 = false ]; then
  RELEASE_LOVE=true
  RELEASE_OSX=true
  RELEASE_WIN_32=true
  RELEASE_WIN_64=true
fi
LOVE_SUPPORT_WIN_64=`echo "${LOVE_VERSION#[0-9]\.}>=8.0" | bc`


## Releases generation ##
mkdir -p $RELEASE_DIR $CACHE_DIR

rm -rf $RELEASE_DIR/$PROJECT_NAME.love 2> /dev/null
if [ -z $PROJECT_FILES ]; then
  zip -r $RELEASE_DIR/$PROJECT_NAME.love -x $0 ${RELEASE_DIR##/*/}/ ${RELEASE_DIR##/*/}/* @ * 
else
  zip -r $RELEASE_DIR/$PROJECT_NAME.love -x $0 ${RELEASE_DIR##/*/}/ ${RELEASE_DIR##/*/}/* @ $PROJECT_FILES
fi
cd $RELEASE_DIR


## Windows 32-bits ##
if [ $RELEASE_WIN_32 = true ]; then
  if [ -f $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ]; then
    cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./
  else
    wget -O $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x86.zip
    cp $CACHE_DIR/love-$LOVE_VERSION-win-x86.zip ./
  fi
  unzip -qq love-$LOVE_VERSION-win-x86.zip
  rm -rf $PROJECT_NAME-win-x86.zip 2> /dev/null
  cat love-$LOVE_VERSION-win-x86/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win-x86/$PROJECT_NAME.exe
  rm love-$LOVE_VERSION-win-x86/love.exe
  zip -qr $PROJECT_NAME-win-x86.zip love-$LOVE_VERSION-win-x86
  rm -rf love-$LOVE_VERSION-win-x86.zip love-$LOVE_VERSION-win-x86
fi

## Windows 64-bits ##
if [ $LOVE_SUPPORT_WIN_64 = "1" ] &&  [ $RELEASE_WIN_64 = true ]; then
  if [ -f $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ]; then
    cp $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ./
  else
    wget -O $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x64.zip
    cp $CACHE_DIR/love-$LOVE_VERSION-win-x64.zip ./
  fi
  unzip -qq love-$LOVE_VERSION-win-x64.zip
  rm -rf $PROJECT_NAME-win-x64.zip 2> /dev/null
  cat love-$LOVE_VERSION-win-x64/love.exe $PROJECT_NAME.love > love-$LOVE_VERSION-win-x64/$PROJECT_NAME.exe
  rm love-$LOVE_VERSION-win-x64/love.exe
  zip -qr $PROJECT_NAME-win-x64.zip love-$LOVE_VERSION-win-x64
 rm -rf love-$LOVE_VERSION-win-x64.zip love-$LOVE_VERSION-win-x64
fi

## Mac OS X ##
if [ $RELEASE_OSX = true ]; then
  if [ -f $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ]; then
    cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
  else
    wget -O $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-ub.zip
    cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
  fi
  unzip -qq love-$LOVE_VERSION-macosx-ub.zip
  rm -rf $PROJECT_NAME-osx.zip 2> /dev/null
  mv love.app $PROJECT_NAME.app
  cp $PROJECT_NAME.love $PROJECT_NAME.app/Contents/Resources
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
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
    <string>Love.icns</string>
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
    <key>DTPlatformBuild</key>
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
</plist>
' > $PROJECT_NAME.app/Contents/Info.plist
  zip -qr $PROJECT_NAME-osx.zip $PROJECT_NAME.app
  rm -rf love-$LOVE_VERSION-macosx-ub.zip $PROJECT_NAME.app
fi

## Love file ##
if [ $RELEASE_LOVE = false ]
then
  rm $PROJECT_NAME.love
fi

echo "Done !"
