# Example
return

# This example script should show you how to write a module for love-release.

# What's the point anyway ?
# Well, you could do that if you wanted to support another platform,
# or maybe to set up your own build script if you'd want to use old or custom versions of love,
# or finally to add other directives at build time.


# Read this example and take a look at the other modules.
# To create a new module, you have to create a file in this directory,
# and to edit the main love-release script.
# If you wish to submit a new module, please also edit README.md and love-release.1
# You could add configuration options in config.ini too,
# but the name of the section must be the same as the name of the script.


# Love-release script

## 1. Register your module
# To register your platforms scripts, you have to choose a command name that will trigger your script.
# It must be followed by:
# - a semicolon ";" if it doesn't require an argument
# - a dot "." if it has an optional argument
# - a colon ":" if it requires an argument
# If you need options that might conflict by their names with already defined options, please prefix them.
# If you want automatic completion to be available, add them to completion.sh
SCRIPT_ARGS="q; wer: ty. uiop $SCRIPT_ARGS"

# If some options require a file or a directory as argument,
# and this file should be excluded by zip, add the option.
EXCLUDE_OPTIONS=("wer")
EXCLUDE_CONFIG=("INI__q__wer")

## 2. Add a short summary of your module
SHORT_HELP=" -q    Create an Example application"

## 3. Source your script at the end of the file in the getoptex loop
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "q" ]; then
        source "$PLATFORMS_DIR"/example.sh
    fi
done


# Module script

## 0. Theses variables are available:
## $MAIN_CACHE_DIR  - if you need to cache something independant from love version
## $CACHE_DIR       - if you need to cache something dependant from love version
## $PROJECT_FILES   - if empty, means *
## $EXCLUDE_FILES   - add files to be excluded by zip.
## $PROJECT_NAME
## $PROJECT_DIR
## $RELEASE_DIR
## $LOVE_FILE       - points to the love file

## 1. Init the module
### $1: Module name
init_module "Example"

## 2. Read the configuration
# Syntax is ${INI__section__variable}
if [ "$CONFIG" = true ]; then
    if [ -n "${INI__q__wer}" ]; then
        WER=${INI__q__wer}
    fi
    if [ -n "${INI__q__ty}" ]; then
        TY=${INI_q_ty}
    fi
    if [ -n "${INI__q__uiop}" ]; then
        UIOP=true
    fi
fi

## 3. Parse the options
# $OPTOPT holds the option and $OPTARG holds the eventual argument passed to it.
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "wer" ]; then
        WER=$OPTARG
    elif [ "$OPTOPT" = "ty" ]; then
        TY=$OPTARG
    elif [ "$OPTOPT" = "uiop" ]; then
        UIOP=true
    fi
done

## 4. Create the love file
### $1: Compression level 0-9
create_love_file 9


## 5. Write your code


## 6. Unset every variable passed by configuration or command-line
unset WER TY UIOP

## 7. Exit the module
### $1: exit code. 0 - success, other - failure
### $2: error message
exit_module

