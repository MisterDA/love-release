# Windows
init_module "Windows" "windows" "w"
OPTIONS="w"
LONG_OPTIONS=""


PACKAGE_NAME=$(echo $PROJECT_NAME | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')

# Configuration
if [ "$CONFIG" = true ]; then
    RELEASE_WIN_32=true
    RELEASE_WIN_64=true
    if [ -n "${INI__windows__icon}" ]; then
        PROJECT_ICO=${INI__windows__icon}
    fi
    if [ "${INI__windows__installer}" = true ]; then
        INSTALLER=true
    fi
    if [ -n "${INI__windows__package_version}" ]; then
        PACKAGE_VERSION=${INI__debian__package_version}
    fi
    if [ -n "${INI__windows__maintainer_name}" ]; then
        MAINTAINER_NAME=${INI__debian__maintainer_name}
    fi
    if [ -n "${INI__windows__package_name}" ]; then
        PACKAGE_NAME=${INI__debian__package_name}
    fi
    if [ -n "${INI__windows__appid}" ]; then
        APPID=${INI__windows__appid}
    fi
fi


# Options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "win-icon" ]; then
        PROJECT_ICO=$OPTARG
    elif [ "$OPTOPT" = "win-installer" ]; then
        INSTALLER=true
    elif [ "$OPTOPT" = "win-package-version" ]; then
        PACKAGE_VERSION=$OPTARG
    elif [ "$OPTOPT" = "win-maintainer-name" ]; then
        MAINTAINER_NAME=$OPTARG
    elif [ "$OPTOPT" = "win-package-name" ]; then
        PACKAGE_NAME=$OPTARG
    elif [ "$OPTOPT" = "win-appid" ]; then
        APPID=$OPTARG
    fi
done


# Wine
FOUND_WINE=true
command -v wine   >/dev/null 2>&1 || { FOUND_WINE=false; }
if [ "$FOUND_WINE" = true ]; then
    WINEPREFIX="$MAIN_CACHE_DIR"/wine
    mkdir -p "$WINEPREFIX"/drive_c
    if [ -n "$PROJECT_ICO" ]; then
        RESHACKER="$WINEPREFIX"/drive_c/"Program Files (x86)"/"Resource Hacker"/ResHacker.exe
        if [ ! -f "$RESHACKER" ]; then
            curl -L -C - -o "$WINEPREFIX"/drive_c/reshack_setup.exe http://www.angusj.com/resourcehacker/reshack_setup.exe
            WINEPREFIX="$WINEPREFIX" wine "$WINEPREFIX/drive_c/reshack_setup.exe"
        fi
    fi
    if [ "$INSTALLER" = true ]; then
        INNOSETUP="$WINEPREFIX"/drive_c/"Program Files (x86)"/"Inno Setup 5"/ISCC.exe
        if [ ! -f "$INNOSETUP" ]; then
           curl -L -C - -o "$WINEPREFIX"/drive_c/is-unicode.exe http://www.jrsoftware.org/download.php/is-unicode.exe
            WINEPREFIX="$WINEPREFIX" wine "$WINEPREFIX/drive_c/is-unicode.exe"
        fi
    fi
else
    unset PROJECT_ICO INSTALLER
fi

# Inno Setup
# $1: Path to game exe directory
# $2: true if 64 bits release
create_installer () {
    ln -s "$RELEASE_DIR"/"$1" "$WINEPREFIX"/drive_c/game
    if [ -n "$PROJECT_ICO" ]; then
        ln -s "$RELEASE_DIR"/"$PROJECT_ICO" "$WINEPREFIX"/drive_c/game.ico
    else
        ln -s "$RELEASE_DIR"/"$1"/game.ico "$WINEPREFIX"/drive_c/game.ico
    fi

    sed -e "s/#define MyAppName \"\"/#define MyAppName \"$PROJECT_NAME\"/" \
        -e "s/#define MyAppVersion \"\"/#define MyAppVersion \"$PACKAGE_VERSION\"/" \
        -e "s/#define MyAppPublisher \"\"/#define MyAppPublisher \"$MAINTAINER_NAME\"/" \
        -e "s/#define MyAppURL \"\"/#define MyAppURL \"$HOMEPAGE\"/" \
        -e "s/#define MyAppExeName \"\"/#define MyAppExeName \"${PROJECT_NAME}.exe\"/" \
        -e "s/AppId={{}/AppId={{$APPID}/" \
        -e "s/OutputBaseFilename=/OutputBaseFilename=${PACKAGE_NAME}-setup/" \
        -e 's/SetupIconFile=/SetupIconFile=C:\\game.ico/' \
        "$PLATFORMS_DIR"/assets/innosetup.iss > "$WINEPREFIX"/drive_c/innosetup.iss
    if [ "$2" = true ]; then
        sed -i 's/;ArchitecturesInstallIn64BitMode/ArchitecturesInstallIn64BitMode/' \
            "$WINEPREFIX"/drive_c/innosetup.iss
    fi

    for file in $(ls -AC1 "$1"); do
        echo "Source: \"C:\\game\\$file\"; DestDir: \"{app}\"; Flags: ignoreversion" \
            >> "$WINEPREFIX"/drive_c/innosetup.iss
    done

    WINEPREFIX="$WINEPREFIX" wine "$INNOSETUP" /Q 'c:\innosetup.iss'
    mv "$WINEPREFIX"/drive_c/Output/"$PACKAGE_NAME"-setup.exe .
    rm -rf "$WINEPREFIX"/drive_c/{game,game.ico,innosetup.iss,Output}
}

# Missing commands
MISSING_INFO=0
ERROR_MSG="Could not build Windows installer."
if [ -z "$PACKAGE_VERSION" ] && [ "$INSTALLER" = true ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing project's version. Use --win-package-version."
fi
if [ -z "$PROJECT_HOMEPAGE" ] && [ "$INSTALLER" = true ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing project's homepage. Use --homepage."
fi
if [ -z "$MAINTAINER_NAME" ] && [ "$INSTALLER" = true ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing maintainer's name. Use --win-maintainer-name."
fi
if [ -z "$APPID" ] && [ "$INSTALLER" = true ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing application GUID. Use --win-appid."
fi

if [ "$MISSING_INFO" -eq 1  ]; then
    exit_module "$MISSING_INFO" "$ERROR_MSG"
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

    if [ -n "$PROJECT_ICO" ]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" \
            -addoverwrite "love-$LOVE_VERSION-win32/love.exe,love-$LOVE_VERSION-win32/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win32/love.exe "$LOVE_FILE" > love-$LOVE_VERSION-win32/"$PROJECT_NAME".exe
    rm love-$LOVE_VERSION-win32/love.exe
    mv love-$LOVE_VERSION-win32 "$PROJECT_NAME"-win32
    if [ "$INSTALLER" = true ]; then
        rm -rf "$PACKAGE_NAME"-setup-win32.exe 2> /dev/null
        create_installer "$PROJECT_NAME-win32"
        mv "$PACKAGE_NAME"-setup.exe "$PACKAGE_NAME"-setup-win32.exe
    else
        rm -rf "$PROJECT_NAME"-win32.zip 2> /dev/null
        zip -9 -qr "$PROJECT_NAME"-win32.zip "$PROJECT_NAME"-win32
    fi
    rm -rf love-$LOVE_VERSION-win32.zip "$PROJECT_NAME"-win32
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

    if [ -n "$PROJECT_ICO" ]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" \
            -addoverwrite "love-$LOVE_VERSION-win64/love.exe,love-$LOVE_VERSION-win64/love.exe,"$PROJECT_ICO",ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win64/love.exe "$LOVE_FILE" > love-$LOVE_VERSION-win64/"$PROJECT_NAME".exe
    rm love-$LOVE_VERSION-win64/love.exe
    mv love-$LOVE_VERSION-win64 "$PROJECT_NAME"-win64
    if [ "$INSTALLER" = true ]; then
        rm -rf "$PACKAGE_NAME"-setup-win64.exe 2> /dev/null
        create_installer "$PROJECT_NAME-win64" "true"
        mv "$PACKAGE_NAME"-setup.exe "$PACKAGE_NAME"-setup-win64.exe
    else
        rm -rf "$PROJECT_NAME"-win64.zip 2> /dev/null
        zip -9 -qr "$PROJECT_NAME"-win64.zip "$PROJECT_NAME"-win64
    fi
    rm -rf love-$LOVE_VERSION-win64.zip "$PROJECT_NAME"-win64
fi


unset PROJECT_ICO APPID INSTALLER PACKAGE_NAME PACKAGE_VERSION MAINTAINER_NAME
exit_module

