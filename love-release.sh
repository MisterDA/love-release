#!/usr/bin/env bash

# LÖVE version
LOVE_DEF_VERSION=0.9.2



# Helper functions

# Dependencies check
check_deps () {
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

# Get user confirmation, simple Yes/No question
## $1: message, usually just a question
## $2: default choice, 0 - yes; 1 - no, default - yes
## return: 0 - yes, 1 - no
get_user_confirmation () {
    if [[ -z $2 || $2 == "0" ]]; then
        read -n 1 -p "$1 [Y/n]: " yn
        local default=0
    else
        read -n 1 -p "$1 [y/N]: " yn
        local default=1
    fi
    case $yn in
        [Yy]* )
            echo; return 0;;
        [Nn]* )
            echo; return 1;;
        "" )
            return $default;;
        * )
            echo; return $default;;
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
## return: 0 - true, 1 - false
compare_version () {
    if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local v1_maj=${BASH_REMATCH[1]}
        local v1_min=${BASH_REMATCH[2]}
        local v1_rev=${BASH_REMATCH[3]}
    else
        return 1
    fi
    if [[ $2 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local v2_maj=${BASH_REMATCH[1]}
        local v2_min=${BASH_REMATCH[2]}
        local v2_rev=${BASH_REMATCH[3]}
    else
        return 1
    fi

    case $2 in
        ge|\>= )
            if (( $v1_maj >= $v2_maj && $v1_min >= $v2_min && $v1_rev >= $v2_rev )); then
                return 0
            else
                return 1
            fi
            ;;
        le|\<= )
            if (( $v1_maj <= $v2_maj && $v1_min <= $v2_min && $v1_rev <= $v2_rev )); then
                return 0
            else
                return 1
            fi
            ;;
        gt|\> )
            if (( $v1_maj > $v2_maj || ( $v1_max == $v2_max && $v1_min > $v2_min ) ||
                ( $v1_max == $v2_max && $v1_min == $v2_min && $v1_rev > $v2_rev ) )); then
                return 0
            else
                return 1
            fi
            ;;
        lt|\< )
            if (( $v1_maj < $v2_maj || ( $v1_max == $v2_max && $v1_min < $v2_min ) ||
                ( $v1_max == $v2_max && $v1_min == $v2_min && $v1_rev < $v2_rev ) )); then
                return 0
            else
                return 1
            fi
            ;;
    esac
}


# Escape directory name for zip
## $1: directory path
## echo: escaped directory path
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

if os == "default" then
    if not t.os then t.os = {} end
    if not t.os.love then t.os.love = {} end
    os = "love"
end

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
    t.os.windows.x32 = t.os.windows.x32 and true or false
    t.os.windows.x64 = t.os.windows.x64 and true or false
    t.os.windows.installer = t.os.windows.installer and true or false
    t.os.windows.appid = t.os.windows.appid or ""
    print("X32="..tostring(t.os.windows.x32))
    print("X64="..tostring(t.os.windows.x64))
    print("INSTALLER="..tostring(t.os.windows.installer))
    print("APPID="..t.os.windows.appid)
end
EOF
)
        eval "$var"
    fi
}

# Test if default module should be executed
default_module () {
    if [[ $? -ne 2 ]]; then
        DEFAULT_MODULE=false
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
## return: 0 - if module should be executed, else exit 2
execute_module () {
    local module="$1"
    read_config "$module"
    module=${module^^}
    if [[ ${!module} == true ]]; then
        if compare_version "$LOVE_VERSION" ">" "$VERSION"; then
            echo "LÖVE $LOVE_VERSION is out ! Your project uses LÖVE ${VERSION}."
            gen_version $VERSION
            unset VERSION
        fi
        return 0
    else
        exit_module "execute"
    fi
}

# Init module
## $1: Pretty module name
init_module () {
    MODULE="$1"
    mkdir -p "$RELEASE_DIR"
    mkdir -p "$CACHE_DIR"
    echo "Generating $TITLE with LÖVE $LOVE_VERSION for ${MODULE}..."
}

# Create the LÖVE file
## $1: Compression level 0-9
create_love_file () {
    LOVE_FILE="$RELEASE_DIR"/"$TITLE".love
    zip -FS -$1 -r "$LOVE_FILE" \
        -x "$0" "${RELEASE_DIR#$PWD/}/*" \
        $(ls -Ap | grep "^\." | sed -e 's/^/\//g' -e 's/\/$/\/*/g') @ \
        .
}

# Exit module
## $1: optional error identifier
## $2: optional error message, printed if $1=="undef" or unidentified error
exit_module () {
    if [[ -z $1 ]]; then
        echo "Done !"
        exit 0
    fi
    case $1 in
        execute )
            exit 2 ;;
        binary )
            >&2 echo "LÖVE $LOVE_VERSION could not be found or downloaded."
            exit 3 ;;
        undef|* )
            if [[ -n $2 ]]; then
                >&2 echo "$2"
            fi
            exit 1 ;;
    esac
}



# Main

check_deps

# Get latest LÖVE version number
gen_version $LOVE_DEF_VERSION
LOVE_WEB_VERSION=$(curl -s https://love2d.org/releases.xml | grep -m 2 "<title>" | tail -n 1 | grep -Eo "[0-9]+.[0-9]+.[0-9]+")
gen_version $LOVE_WEB_VERSION

INSTALLED=false
EMBEDDED=false

DEFAULT_MODULE=true

TITLE="$(basename $(pwd))"
RELEASE_DIR=releases
CACHE_DIR=~/.cache/love-release

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
        default_module
    done
fi


(
    (execute_module "love")
    if [[ $? -eq 0 || $DEFAULT_MODULE == true ]]; then
        read_config "default"
        init_module "LÖVE"
        create_love_file 9
        exit_module
    fi
)

exit 0

