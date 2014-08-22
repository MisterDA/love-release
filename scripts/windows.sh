# Windows
init_module "Windows"


# Configuration
if [ "$CONFIG" = true ]; then
    RELEASE_WIN_32=true
    RELEASE_WIN_64=true
    if [ -n "${INI__windows__icon}" ]; then
        PROJECT_ICO=${INI__windows__icon}
    fi
fi


# Options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "icon" ]; then
        PROJECT_ICO=$OPTARG
    fi
done
EXCLUDE_FILES="$EXCLUDE_FILES $PROJECT_ICO"

# Wine
FOUND_WINE=true
command -v wine   >/dev/null 2>&1 || { FOUND_WINE=false; }
if [ "$FOUND_WINE" = true ] && [ -n "$PROJECT_ICO" ]; then
    WINEPREFIX="$MAIN_CACHE_DIR"/wine
    mkdir -p "$WINEPREFIX"/drive_c
    RESHACKER="$WINEPREFIX"/drive_c/"Program Files (x86)"/"Resource Hacker"/ResHacker.exe
    if [ -f "$RESHACKER" ]; then
        :
    else
        curl -L -C - -o "$WINEPREFIX"/drive_c/reshack_setup.exe http://www.angusj.com/resourcehacker/reshack_setup.exe
        WINEPREFIX="$WINEPREFIX" wine "$WINEPREFIX/drive_c/reshack_setup.exe"
    fi
fi


create_love_file 9


# Windows 32-bits
if [ "$RELEASE_WIN_32" = true ]; then

    if [ "$LOVE_GT_090" = true ]; then
        if [ -f "$CACHE_DIR"/love-$LOVE_VERSION-win32.zip ]; then
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win32.zip ./
        else
            curl -L -C - -o "$CACHE_DIR"/love-$LOVE_VERSION-win32.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win32.zip
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win32.zip ./
        fi
    else
        if [ -f "$CACHE_DIR"/love-$LOVE_VERSION-win-x86.zip ]; then
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win-x86.zip ./love-$LOVE_VERSION-win32.zip
        else
            curl -L -C - -o "$CACHE_DIR"/love-$LOVE_VERSION-win-x86.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x86.zip
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win-x86.zip ./love-$LOVE_VERSION-win32.zip
        fi
    fi

    unzip -qq love-$LOVE_VERSION-win32.zip
    rm -rf "$PROJECT_NAME"-win32.zip 2> /dev/null

    if [ "$FOUND_WINE" = true ] && [ -n "$PROJECT_ICO" ]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" -addoverwrite "love-$LOVE_VERSION-win32/love.exe,love-$LOVE_VERSION-win32/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win32/love.exe "$LOVE_FILE" > love-$LOVE_VERSION-win32/"$PROJECT_NAME".exe
    rm love-$LOVE_VERSION-win32/love.exe
    zip -9 -qr "$PROJECT_NAME"-win32.zip love-$LOVE_VERSION-win32
    rm -rf love-$LOVE_VERSION-win32.zip love-$LOVE_VERSION-win32
fi

## Windows 64-bits ##
if [ "$RELEASE_WIN_64" = true ] && [ "$LOVE_GT_080" = true ]; then

    if [ "$LOVE_GT_090" = true ]; then
        if [ -f "$CACHE_DIR"/love-$LOVE_VERSION-win64.zip ]; then
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win64.zip ./
        else
            curl -L -C - -o "$CACHE_DIR"/love-$LOVE_VERSION-win64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win64.zip
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win64.zip ./
        fi
    else
        if [ -f "$CACHE_DIR"/love-$LOVE_VERSION-win-x64.zip ]; then
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win-x64.zip ./love-$LOVE_VERSION-win64.zip
        else
            curl -L -C - -o "$CACHE_DIR"/love-$LOVE_VERSION-win-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x64.zip
            cp "$CACHE_DIR"/love-$LOVE_VERSION-win-x64.zip ./love-$LOVE_VERSION-win64.zip
        fi
    fi

    unzip -qq love-$LOVE_VERSION-win64.zip
    rm -rf "$PROJECT_NAME"-win64.zip 2> /dev/null

    if [ "$FOUND_WINE" = true ] && [ -n "$PROJECT_ICO" ]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" -addoverwrite "love-$LOVE_VERSION-win32/love.exe,love-$LOVE_VERSION-win32/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win64/love.exe "$LOVE_FILE" > love-$LOVE_VERSION-win64/"$PROJECT_NAME".exe
    rm love-$LOVE_VERSION-win64/love.exe
    zip -9 -qr "$PROJECT_NAME"-win64.zip love-$LOVE_VERSION-win64
    rm -rf love-$LOVE_VERSION-win64.zip love-$LOVE_VERSION-win64
fi


unset PROJECT_ICO
exit_module

