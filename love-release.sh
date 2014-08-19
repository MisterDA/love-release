#!/usr/bin/env bash


# Edit this if you want to use another Love version by default
LOVE_VERSION=0.9.1


# Platform-specific scripts registration

## To register your platforms scripts, you have to choose a command name that will trigger your script.
## It must be followed by:
## - a semicolon ";" if it doesn't require an argument
## - a dot "." if it has an optional argument
## - a colon ":" if it requires an argument

## SCRIPT_ARGS="a; osname:"
SCRIPT_ARGS="l; w."

## Windows
SCRIPT_ARGS="icon: $SCRIPT_ARGS"

## Add a short summary of your platform script here
## SHORT_HELP=" -a    Create an executable for a
##  --osname    Create an executable for osname"
SHORT_HELP=" -l    Create a plain Love file
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
SCRIPT_ARGS="$SCRIPT_ARGS h; v: refresh help"

PROJECT_FILES=
EXCLUDE_FILES=$(/bin/ls -A | grep "^[.]" | tr '\n' ' ')

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


# Parsing options
source "$INCLUDE_DIR"/getopt.sh
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "h" ]; then
        echo "$SHORT_HELP"
    elif [ "$OPTOPT" = "help" ]; then
        :
    elif [ "$OPTOPT" = "n" ]; then
        PROJECT_NAME=$OPTARG
    elif [ "$OPTOPT" = "r" ]; then
        RELEASE_DIR=$OPTARG
    elif [ "$OPTOPT" = "v" ]; then
        LOVE_VERSION=$OPTARG
        LOVE_VERSION_MAJOR=$(echo "$LOVE_VERSION" | grep -Eo '^[0-9]+\.?[0-9]*')
        LOVE_GT_080=$(float_test "$LOVE_VERSION_MAJOR >= 0.8")
        LOVE_GT_090=$(float_test "$LOVE_VERSION_MAJOR >= 0.9")
    elif [ "$OPTOPT" = "refresh" ]; then
        rm -rf "$MAIN_CACHE_DIR"
    fi
done
shift $((OPTIND-1))
for file in "$@"
do
    PROJECT_FILES="$PROJECT_FILES $file"
done

set -- ${ARGS[@]}
unset OPTIND
unset OPTOFS


# Modules functions
init_module ()
{
    unset OPTIND
    unset OPTOFS
    MAIN_RELEASE_DIR="${RELEASE_DIR##/*/}"
    RELEASE_DIR="$RELEASE_DIR"/$LOVE_VERSION
    CACHE_DIR="$MAIN_CACHE_DIR"/$LOVE_VERSION
    mkdir -p "$RELEASE_DIR" "$CACHE_DIR"
    rm -rf "$RELEASE_DIR"/"$PROJECT_NAME".love 2> /dev/null
    echo "Generating $PROJECT_NAME with Love $LOVE_VERSION for $1..."
}

create_love_file ()
{
    cd "$PROJECT_DIR"
    rm -rf "$RELEASE_DIR"/"$PROJECT_NAME".love 2> /dev/null
    if [ -z "$PROJECT_FILES" ]; then
        zip -9 -r "$RELEASE_DIR"/"$PROJECT_NAME".love -x "$0" "$MAIN_RELEASE_DIR"/\* $EXCLUDE_FILES @ *
    else
        zip -9 -r "$RELEASE_DIR"/"$PROJECT_NAME".love -x "$0" "$MAIN_RELEASE_DIR"/\* $EXCLUDE_FILES @ $PROJECT_FILES
    fi
    cd "$RELEASE_DIR"
    LOVE_FILE="$PROJECT_NAME".love
}

remove_love_file ()
{
    rm -rf "$LOVE_FILE"
}

exit_module ()
{
    if [ -z $2 ]; then
        echo "Done !"
    else
        echo $2
    fi
    exit $1
}



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



# Fallback if nothing is specified
init_module "Love"
create_love_file
exit_module

