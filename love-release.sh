#!/usr/bin/env bash

# LÖVE version
LOVE_DEF_VERSION=0.9.2



# Helper functions

# Dependencies check
check_deps ()
{
    command -v curl  > /dev/null 2>&1 || {
        echo "curl is not installed. Aborting."
        local EXIT=true
    }
    command -v zip   > /dev/null 2>&1 || {
        echo "zip is not installed. Aborting."
        local EXIT=true
    }
    command -v unzip > /dev/null 2>&1 || {
        echo "unzip is not installed. Aborting."
        local EXIT=true
    }
    command -v lua   > /dev/null 2>&1 || {
        echo "lua is not installed. Install it to ease your releases."
    } && {
        LUA=true
    }
    if [[ $EXIT == true ]]; then
        exit 1
    fi
}

# Reset script variables
reset_vars () {
    TITLE="$(basename $(pwd))"
    MODULE=
    RELEASE_DIR=releases
    CACHE_DIR=~/.cache/love-release
}

# Get user confirmation, simple Yes/No question
## $1: message, usually just a question
## $2: default choice, 0 - no; 1 - yes, default - yes
## return: true - yes
get_user_confirmation () {
    if [[ $2 == "0" ]]; then
        read -n 1 -p "$1 [y/N]: " yn
        local default=false
    else
        read -n 1 -p "$1 [Y/n]: " yn
        local default=true
    fi
    case $yn in
        [Yy]* )
            echo "true"; echo >> "$(tty)";;
        [Nn]* )
            echo "false"; echo >> "$(tty)";;
        "" )
            echo "$default";;
        * )
            echo "$default"; echo >> "$(tty)";;
    esac
}


# Generate LÖVE version variables
## $1: LÖVE version string
gen_version () {
    if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        LOVE_VERSION=$1
        LOVE_VERSION_MAJOR=${BASH_REMATCH[1]}
        LOVE_VERSION_MINOR=${BASH_REMATCH[2]}
        LOVE_VERSION_REVISION=${BASH_REMATCH[3]}
    fi
}


# Compare two LÖVE versions
## $1: First LÖVE version
## $2: comparison operator
##     "ge", "le", "gt" "lt"
##     ">=", "<=", ">", "<"
## $3: Second LÖVE version
## return: "true" or "false"
compare_version () {
    if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local v1_maj=${BASH_REMATCH[1]}
        local v1_min=${BASH_REMATCH[2]}
        local v1_rev=${BASH_REMATCH[3]}
    else
        echo "false"
        return
    fi
    if [[ $2 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local v2_maj=${BASH_REMATCH[1]}
        local v2_min=${BASH_REMATCH[2]}
        local v2_rev=${BASH_REMATCH[3]}
    else
        echo "false"
        return
    fi

    case $2 in
        ge|\>= )
            if (( $v1_maj >= $v2_maj && $v1_min >= $v2_min && $v1_rev >= $v2_rev )); then
                echo "true"
            else
                echo "false"
            fi
            ;;
        le|\<= )
            if (( $v1_maj <= $v2_maj && $v1_min <= $v2_min && $v1_rev <= $v2_rev )); then
                echo "true"
            else
                echo "false"
            fi
            ;;
        gt|\> )
            if (( $v1_maj > $v2_maj || ( $v1_max == $v2_max && $v1_min > $v2_min ) ||
                ( $v1_max == $v2_max && $v1_min == $v2_min && $v1_rev > $v2_rev ) )); then
                echo "true"
            else
                echo "false"
            fi
            ;;
        lt|\< )
            if (( $v1_maj < $v2_maj || ( $v1_max == $v2_max && $v1_min < $v2_min ) ||
                ( $v1_max == $v2_max && $v1_min == $v2_min && $v1_rev < $v2_rev ) )); then
                echo "true"
            else
                echo "false"
            fi
            ;;
    esac
}


# Escape directory name for zip
## $1: directory path
## return: escaped directory path
dir_escape () {
    local dir="$1"
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


# Read configuration
## $1: system name
read_config () {
    if [[ $LUA == true ]] && [[ -f "conf.lua" ]]; then
        local var=$(lua - <<EOF
f = loadfile("conf.lua")
t, love = {window = {}, modules = {}, screen = {}}, {}
f()
love.conf(t)

-- "love", "windows", "osx", "debian" or "android"
os = "$1"

fields = {
    "identity", "version", "game_version", "icon", "exclude",
    "title", "author", "email", "url", "description", }

for _, f in ipairs(fields) do
    t[f] = t[f] or ""
end

for _, v in ipairs(t.os) do
    t.os[v] = {}
end

if not t.os or #t.os == 0 then t.os.love = {} end

if t.os[os] then
    print(os:upper()..'=true')
    for _, f in ipairs(fields) do
        t.os[os][f] = t.os[os][f] or t[f]
        if type(t.os[os][f]) == "table" then
            str = f:upper()..'=('
            for _, v in ipairs(t.os[os][f]) do
                str = str..' "'..v..'"'
            end
            str = str..' )'
            print(str)
        else
            print(f:upper()..'="'..t.os[os][f]..'"')
        end
    end
else
    print(os:upper()..'=false')
end

if t.os.windows and os == "windows" then
    t.os.windows.x86 = t.os.windows.x86 and true or false
    t.os.windows.x64 = t.os.windows.x64 and true or false
    t.os.windows.installer = t.os.windows.installer and true or false
    t.os.windows.appid = t.os.windows.appid or ""
    print("X86="..tostring(t.os.windows.x86))
    print("X64="..tostring(t.os.windows.x64))
    print("INSTALLER="..tostring(t.os.windows.installer))
    print("APPID="..t.os.windows.appid)
end
EOF
)
        eval "$var"
        if [[ $(compare_version "$LOVE_VERSION" ">" "$VERSION") == true ]]; then
            if [[ $(get_user_confirmation "LÖVE $LOVE_VERSION is out ! Your project uses LÖVE $VERSION. Continue ?") == false ]]; then
                exit
            fi
            gen_version $VERSION
            unset VERSION
        fi
    fi
}

dump_var () {
    echo "LOVE_VERSION=$LOVE_VERSION"
    echo "LOVE_DEF_VERSION=$LOVE_DEF_VERSION"
    echo "LOVE_WEB_VERSION=$LOVE_WEB_VERSION"
    echo
    echo "RELEASE_DIR=$RELEASE_DIR"
    echo "CACHE_DIR=$CACHE_DIR"
    echo
    echo "IDENTITY=$IDENTITY"
    echo "GAME_VERSION=$GAME_VERSION"
    echo "ICON=$ICON"
    echo
    echo "TITLE=$TITLE"
    echo "AUTHOR=$AUTHOR"
    echo "EMAIL=$EMAIL"
    echo "URL=$URL"
    echo "DESCRIPTION=$DESCRIPTION"
}


# Modules functions

# Test if module should be executed
## $1: Module name
## return: true if module should be executed
execute_module ()
{
    reset_vars
    local module="$1"
    MODULE="$module"
    read_config "$module"
    module=${module^^}
    if [[ ${!module} == true ]]; then
        if [[ -z $DEFAULT_MODULE ]]; then
            if [[ ${module} == "LOVE" ]]; then
                DEFAULT_MODULE=true
            else
                DEFAULT_MODULE=false
            fi
        fi
    else
        reset_vars
    fi
    echo "${!module}"
}

# Init module
## $1: Pretty module name
init_module ()
{
    MODULE="$1"
    mkdir -p "$RELEASE_DIR"
    mkdir -p "$CACHE_DIR"
    echo "Generating $TITLE with LÖVE $LOVE_VERSION for ${MODULE}..."
}

# Create the LÖVE file
## $1: Compression level 0-9
create_love_file ()
{
    LOVE_FILE="$RELEASE_DIR"/"$TITLE".love
    zip -FS -$1 -r "$LOVE_FILE" \
        -x "$0" "${RELEASE_DIR#$PWD/}/*" \
        $(ls -Ap | grep "^\." | sed -e 's/^/\//g' -e 's/\/$/\/*/g') @ \
        .
}

# Exit module
## $1: exit code.
##  0 - success
##  1 - binary not found or downloaded
##  other - failure
## $2: error message
exit_module ()
{
    if [[ -z $1 || "$1" == "0" ]]; then
        echo "Done !"
    elif [[ "$1" == "1" ]]; then
        >&2 echo -e "$2"
        >&2 echo "LÖVE $LOVE_VERSION could not be found or downloaded."
    else
        >&2 echo -e "$2"
        exit $1
    fi
}



# Main

check_deps

# Get latest LÖVE version number
gen_version $LOVE_DEF_VERSION
LOVE_WEB_VERSION=$(curl -s https://love2d.org/releases.xml | grep -m 2 "<title>" | tail -n 1 | grep -Eo "[0-9]+.[0-9]+.[0-9]+")
gen_version $LOVE_WEB_VERSION

INSTALLED=false
EMBEDDED=false

DEFAULT_MODULE=

if [[ $INSTALLED == false && $EMBEDDED == false ]]; then
    >&2 echo "love-release has not been installed, and is not embedded into one script. Consider doing one of the two."
    INSTALLED=true
fi

if [[ $EMBEDDED == true ]]; then
    : # include_scripts_here
elif [[ $INSTALLED == true ]]; then
    SCRIPTS_DIR="scripts"
    for file in "$SCRIPTS_DIR"/*.sh; do
        (source "$file")
    done
fi

if [[ -z $DEFAULT_MODULE || $DEFAULT_MODULE == true ]]; then
    (
    reset_vars
    read_config "love"
    init_module "LÖVE"
    create_love_file 9
    exit_module
    )
fi

exit 0

