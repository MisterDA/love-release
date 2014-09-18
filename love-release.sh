#!/usr/bin/env bash


# Edit this if you want to use another Love version by default
LOVE_VERSION=0.9.1


# Platform-specific scripts registration

## To register your platforms scripts, you have to choose a command name that will trigger your script.
## It must be followed by:
## - a semicolon ";" if it doesn't require an argument
## - a dot "." if it has an optional argument
## - a colon ":" if it requires an argument

## Love file
SCRIPT_ARGS="l;"

## Windows
SCRIPT_ARGS="w. win-icon: $SCRIPT_ARGS"

## Debian
SCRIPT_ARGS="d; deb-icon: deb-package-version: deb-maintainer-name: maintainer-email: deb-package-name: $SCRIPT_ARGS"

## Android
SCRIPT_ARGS="a; activity: apk-package-version: apk-maintainer-name: apk-package-name: update-android; $SCRIPT_ARGS"

## Mac OS X
SCRIPT_ARGS="m; osx-icon: osx-maintainer-name: $SCRIPT_ARGS"


## List the options that require a file/directory that should be excluded by zip.
EXCLUDE_OPTIONS=("win-icon" "osx-icon" "deb-icon")
EXCLUDE_CONFIG=("INI__windows__icon" "INI__macosx__icon" "INI__debian__icon")


## Add a short summary of your platform script here
## SHORT_HELP=" -a    Create an executable for a
##  --osname    Create an executable for osname"
SHORT_HELP=" -l    Create a plain Love file
 -a     Create an Android package
 -d    Create a Debian package
 -m    Create a Mac OS X application
 -w,   Create a Windows application
    -w32  Create a Windows x86 application
    -w64  Create a Windows x64 application"

## Don't forget to source the corresponding file at the bottom of the script !



# Test if requirements are installed
command -v curl  >/dev/null 2>&1 || { echo "curl is not installed. Aborting." >&2; exit 1; }
command -v zip   >/dev/null 2>&1 || { echo "zip is not installed. Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is not installed. Aborting." >&2; exit 1; }
FOUND_LUA=true
command -v lua   >/dev/null 2>&1 || { FOUND_LUA=false; }


# Tests on float numbers
float_test () {
    a=$(echo | awk 'END { exit ( !( '"$1"')); }' && echo "true")
    if [ "$a" != "true" ]; then
        a=false
    fi
    echo $a
}

# Escape directory name for zip
dir_escape () {
    dir="$1"
    if [ -d "$dir" ]; then
        if [ "${dir::1}" != "/" ]; then
            dir="/$dir"
        fi
        if [ "${dir: -1}" != "*" ]; then
            if [ "${dir: -1}" != "/" ]; then
                dir="$dir/*"
            else
                dir="$dir*"
            fi
        fi
    fi
    echo "$dir"
}


# Love version detection
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


# Global variables
ARGS=( "$@" )
SCRIPT_ARGS="$SCRIPT_ARGS h; n: r: v: x: config: homepage: description: clean help"
SCRIPT_ARGS=$(printf '%s\n' $SCRIPT_ARGS | sort -u)
CONFIG=false
CONFIG_FILE=config.ini

PROJECT_FILES=
MAIN_EXCLUDE_FILES=

PROJECT_NAME="${PWD##/*/}"
PROJECT_DIR="$PWD"

RELEASE_DIR="$PWD"/releases
MAIN_CACHE_DIR=~/.cache/love-release
INSTALL_DIR=
PLATFORMS_DIR="$INSTALL_DIR"/scripts
INCLUDE_DIR="$INSTALL_DIR"/include

if [ -n "$SHORT_HELP" ] && [ "${SHORT_HELP:$((${#SHORT_HELP}-1)):1}" != $'\n' ]; then
    SHORT_HELP="$SHORT_HELP
"
fi
SHORT_HELP="Usage: love-release.sh [options...] [files...]
Options:
 -h, --help  Prints short or long help
 -n    Set the projects name
 -r    Set the release directory
 -v    Set the Love version
$SHORT_HELP"


# Read config
missing_operands=true
source "$INCLUDE_DIR"/getopt/getopt.sh
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "config" ]; then
        source "$INCLUDE_DIR"/bash_ini_parser/read_ini.sh
        missing_operands=false
        CONFIG_FILE=$OPTARG
        read_ini "$CONFIG_FILE" || exit 1
        CONFIG=true
        SED_ARG=$(echo "$PLATFORMS_DIR" | sed -e 's/[\/&]/\\&/g')
        PLATFORM_SCRIPTS=$(echo "${INI__ALL_SECTIONS}" | sed -r -e 's/[ ]*global[ ]*//g' -e "s/\<[^ ]+\>/$SED_ARG\/&.sh/g")
        IFS=" " read -a PLATFORM_SCRIPTS <<< "$PLATFORM_SCRIPTS"
        if [ -n "${INI__global__release_dir}" ]; then
            RELEASE_DIR=${INI__global__release_dir}
        fi
        if [ -n "${INI__global__love_version}" ]; then
            LOVE_VERSION=${INI__global__love_version}
            LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
            LOVE_GT_080=$(float_test "$LOVE_VERSION_MAJOR >= 0.8")
            LOVE_GT_090=$(float_test "$LOVE_VERSION_MAJOR >= 0.9")
        fi
        if [ -n "${INI__global__project_name}" ]; then
            PROJECT_NAME=${INI__global__project_name}
        fi
        if [ -n "${INI__global__homepage}" ]; then
            PROJECT_HOMEPAGE=${INI__global__homepage}
        fi
        if [ -n "${INI__global__description}" ]; then
            PROJECT_DESCRIPTION=${INI__global__description}
        fi
        for option in "${EXCLUDE_CONFIG[@]}"
        do
            MAIN_EXCLUDE_FILES=$(dir_escape "${!option}") $MAIN_EXCLUDE_FILES
        done
    fi
done
unset OPTIND
unset OPTOFS


# Parsing options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "h" ]; then
        echo "$SHORT_HELP"
        exit
    elif [ "$OPTOPT" = "help" ]; then
        man love-release
        exit
    elif [ "$OPTOPT" = "n" ]; then
        PROJECT_NAME=$OPTARG
    elif [ "$OPTOPT" = "r" ]; then
        RELEASE_DIR=$OPTARG
    elif [ "$OPTOPT" = "v" ]; then
        LOVE_VERSION=$OPTARG
        LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
        LOVE_GT_080=$(float_test "$LOVE_VERSION_MAJOR >= 0.8")
        LOVE_GT_090=$(float_test "$LOVE_VERSION_MAJOR >= 0.9")
    elif [ "$OPTOPT" = "x" ]; then
        MAIN_EXCLUDE_FILES="$(dir_escape "$OPTARG") $MAIN_EXCLUDE_FILES"
    elif [ "$OPTOPT" = "homepage" ]; then
        PROJECT_HOMEPAGE=$OPTARG
    elif [ "$OPTOPT" = "description" ]; then
        PROJECT_DESCRIPTION=$OPTARG
    elif [ "$OPTOPT" = "clean" ]; then
        missing_operands=false
        rm -rf "$MAIN_CACHE_DIR"
    fi
    for option in "${EXCLUDE_OPTIONS[@]}"
    do
        if [ "$OPTOPT" = "$option" ]; then
            MAIN_EXCLUDE_FILES=$(dir_escape "$OPTARG") $MAIN_EXCLUDE_FILES
        fi
    done
done
shift $((OPTIND-1))
for file in "$@"
do
    PROJECT_FILES="$PROJECT_FILES $file"
done

set -- "${ARGS[@]}"
unset OPTIND
unset OPTOFS


# Modules functions
## $1: Module name
init_module ()
{
    GLOBAL_OPTIND=$OPTIND
    GLOBAL_OPTOFS=$OPTOFS
    unset OPTIND
    unset OPTOFS
    EXCLUDE_FILES=$MAIN_EXCLUDE_FILES
    if [ -z "$MAIN_RELEASE_DIR" ]; then
        MAIN_RELEASE_DIR=$(cd "$(dirname "$RELEASE_DIR")" && pwd)/$(basename "$RELEASE_DIR")
        RELEASE_DIR="$MAIN_RELEASE_DIR"/$LOVE_VERSION
    fi
    missing_operands=false
    CACHE_DIR="$MAIN_CACHE_DIR"/$LOVE_VERSION
    mkdir -p "$RELEASE_DIR" "$CACHE_DIR"
    rm -rf "$RELEASE_DIR"/"$PROJECT_NAME".love 2> /dev/null
    echo "Generating $PROJECT_NAME with Love $LOVE_VERSION for $1..."
}

## $1: Compression level 0-9
create_love_file ()
{
    cd "$PROJECT_DIR"
    rm -rf "$RELEASE_DIR"/"$PROJECT_NAME".love 2> /dev/null
    if [ -z "$PROJECT_FILES" ]; then
        zip --filesync -$1 -r "$RELEASE_DIR"/"$PROJECT_NAME".love \
            -x "$0" "${MAIN_RELEASE_DIR#$PWD/}/*" "$CONFIG_FILE" $MAIN_EXCLUDE_FILES $EXCLUDE_FILES \
            $(ls -Ap | grep "^\." | sed -e 's/^/\//g' -e 's/\/$/\/*/g') @ \
            .
    else
        zip --filesync -$1 -r "$RELEASE_DIR"/"$PROJECT_NAME".love \
            -x "$0" "${MAIN_RELEASE_DIR#$PWD/}/*" "$CONFIG_FILE" $MAIN_EXCLUDE_FILES $EXCLUDE_FILES \
            $(ls -Ap | grep "^\." | sed -e 's/^/\//g' -e 's/\/$/\/*/g') @ \
            $PROJECT_FILES
    fi
    cd "$RELEASE_DIR"
    LOVE_FILE="$PROJECT_NAME".love
}

## $1: exit code. 0 - success, other - failure
## $2: error message
exit_module ()
{
    if [ -z "$1" ] || [ "$1" = "0" ]; then
        OPTIND=$GLOBAL_OPTIND
        OPTOFS=$GLOBAL_OPTOFS
        echo "Done !"
    else
        echo -e "$2"
        exit $1
    fi
}

if [ "$CONFIG" = true ]; then
    for script in "${PLATFORM_SCRIPTS[@]}"
    do
        source "$script"
    done
    exit
fi



# Platform-specific scripts registration
## To register your platforms scripts, test for the option you've specified
## at the beginning of the script and source the corresponding file.
## $OPTOPT holds the option and $OPTARG holds the eventual argument passed to it.

## while getoptex "a; osname:" "$@"
while getoptex "$SCRIPT_ARGS" "$@"
do
    :
##  if [ "$OPTOPT" = "a" ]; then
##      source "$PLATFORMS_DIR/a-system.sh"
##  elif [ "$OPTOPT" = "osname" ]; then
##      OSNAME=$OPTARG
##      source "$PLATFORMS_DIR/os.sh"
##  fi
    if [ "$OPTOPT" = "l" ]; then
        source "$PLATFORMS_DIR"/love.sh
    elif [ "$OPTOPT" = "a" ]; then
        source "$PLATFORMS_DIR"/android.sh
    elif [ "$OPTOPT" = "d" ]; then
        source "$PLATFORMS_DIR"/debian.sh
    elif [ "$OPTOPT" = "m" ]; then
        source "$PLATFORMS_DIR"/macosx.sh
    elif [ "$OPTOPT" = "w" ]; then
        if [ "$OPTARG" = "32" ]; then
            RELEASE_WIN_32=true
        elif [ "$OPTARG" = "64" ]; then
            RELEASE_WIN_64=true
        else
            RELEASE_WIN_32=true
            RELEASE_WIN_64=true
        fi
        source "$PLATFORMS_DIR"/windows.sh
    fi
done


# Missing operands
if [ "$missing_operands" = true ]; then
    >&2 echo "./love-release.sh: missing operands.
love-release.sh [-adlmw] [-n project_name] [-r release_dir] [-v love_version] [FILES...]
Try 'love-release.sh --help' for more information."
    exit 1
fi

