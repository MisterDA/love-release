# Windows
init_module "Windows" "windows" "W"
OPTIONS="W"
LONG_OPTIONS="appid:,installer,32,64"

if [[ -z $IDENTITY ]]; then
    IDENTITY=$(echo $IDENTITY | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')
fi

while true; do
    case "$1" in
        --Wappid )     APPID="$2"; shift 2 ;;
        --Winstaller ) INSTALLER=true; shift ;;
        --W32 )        X32=true; shift ;;
        --W64 )        X64=true; shift ;;
        -- ) break ;;
        * ) shift ;;
    esac
done


FOUND_WINE=true
command -v wine >/dev/null 2>&1 || { FOUND_WINE=false; } && { WINEPREFIX="$CACHE_DIR/wine"; }


if [[ -n $ICON ]]; then
    if [[ $FOUND_WINE == true ]]; then
        if [[ -d $ICON ]]; then
            for file in $ICON/*.ico; do
                if [[ -f $file ]]; then
                    ICON="$file"
                    break
                else
                    found=false
                fi
            done
        fi
        if [[ $found == false || ! -f $ICON ]]; then
            >&2 echo "Windows icon was not found in ${ICON}."
            ICON=
        else
            RESHACKER="$WINEPREFIX/drive_c/Program Files (x86)/Resource Hacker/ResourceHacker.exe"
            if [[ ! -f $RESHACKER ]]; then
                curl -L -C - -o "$WINEPREFIX/drive_c/reshacker_setup.exe http://www.angusj.com/resourcehacker/reshacker_setup.exe"
                WINEPREFIX="$WINEPREFIX" wine "$WINEPREFIX/drive_c/reshacker_setup.exe"
            fi
        fi
    else
        >&2 echo "Can not set Windows icon without Wine."
    fi
fi


if [[ $INSTALLER == true ]]; then
    missing_opt=false
    error_msg="Could not build Windows installer."
    if [[ $FOUND_WINE == false ]]; then
        >&2 echo "Can not build Windows installer without Wine."
        exit_module "deps"
    fi
    if [[ -z $AUTHOR ]]; then
        missing_opt=true
        error_msg="$error_msg\nMissing project author. Use -a or --Wauthor."
    fi
    if [[ -z $URL ]]; then
        missing_opt=true
        error_msg="$error_msg\nMissing project url. Use -u or --Wurl."
    fi
    if [[ -z $GAME_VERSION ]]; then
        missing_opt=true
        error_msg="$error_msg\nMissing project version. Use -v or --Wversion."
    fi
    if [[ -z $APPID ]]; then
        missing_opt=true
        error_msg="$error_msg\nMissing application GUID. Use --Wappid."
    fi
    if [[ $missing_opt == true ]]; then
        exit_module "options" "$error_msg"
    fi

    INNOSETUP="$WINEPREFIX/drive_c/Program Files (x86)/Inno Setup 5/ISCC.exe"
    if [[ ! -f $INNOSETUP ]]; then
        curl -L -C - -o "$WINEPREFIX/drive_c/is-unicode.exe http://www.jrsoftware.org/download.php/is-unicode.exe"
        WINEPREFIX="$WINEPREFIX" wine "$WINEPREFIX/drive_c/is-unicode.exe"
    fi

# Inno Setup
# $1: Path to game exe directory
# $2: true if 64 bits release
create_installer () {
    ln -s "$1" "$WINEPREFIX/drive_c/game"
    if [[ -n $ICON ]]; then
        cd "$PROJECT_DIR"
        ln -s "$ICON" "$WINEPREFIX/drive_c/game.ico"
        cd "$RELEASE_DIR"
    else
        ln -s "$1/game.ico" "$WINEPREFIX/drive_c/game.ico"
    fi

    cat > "$WINEPREFIX/drive_c/innosetup.iss" <<EOF
#define MyAppName "$TITLE"
#define MyAppVersion "$GAME_VERSION"
#define MyAppPublisher "$AUTHOR"
#define MyAppURL "$URL"
#define MyAppExeName "${TITLE}.exe"

[Setup]
;ArchitecturesInstallIn64BitMode=x64 ia64
AppId={{$APPID}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputBaseFilename=${IDENTITY}-setup
SetupIconFile=C:\\game.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Files]
EOF
    if [[ $2 == true ]]; then
        sed -i 's/;ArchitecturesInstallIn64BitMode/ArchitecturesInstallIn64BitMode/' "$WINEPREFIX/drive_c/innosetup.iss"
    fi

    for file in $1; do
        echo "Source: \"C:\\game\\$file\"; DestDir: \"{app}\"; Flags: ignoreversion" \
            >> "$WINEPREFIX"/drive_c/innosetup.iss
    done

    WINEPREFIX="$WINEPREFIX" wine "$INNOSETUP" /Q 'c:\innosetup.iss'
    mv "$WINEPREFIX/drive_c/Output/$IDENTITY-setup.exe" .
    rm -rf "$WINEPREFIX/drive_c/{game,game.ico,innosetup.iss,Output}"
}

fi


if [[ ${X32:=false} == false && ${X64:=false} == false ]]; then
    X32=true
    X64=true
fi


create_love_file 9
cd "$RELEASE_DIR"


# Windows 32-bits
if [[ $X32 == true ]]; then

    if [[ ! -f "$CACHE_DIR/love-$LOVE_VERSION-win32.zip" ]]; then
        if compare_version "$LOVE_VERSION" '>=' '0.9.0'; then
            curl -L -C - -o "$CACHE_DIR/love-$LOVE_VERSION-win32.zip" https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win32.zip
        else
            curl -L -C - -o "$CACHE_DIR/love-$LOVE_VERSION-win32.zip" https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x86.zip
        fi
    fi

    unzip -qq "$CACHE_DIR/love-$LOVE_VERSION-win32.zip"

    if [[ -n $ICON ]]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" \
            -addoverwrite "love-$LOVE_VERSION-win32/love.exe,love-$LOVE_VERSION-win32/love.exe,$ICON,ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win32/love.exe "$LOVE_FILE" > "love-$LOVE_VERSION-win32/${TITLE}.exe"
    rm love-$LOVE_VERSION-win32/love.exe
    mv love-$LOVE_VERSION-win32 "$TITLE"-win32
    if [[ $INSTALLER == true ]]; then
        rm -rf "$IDENTITY-setup-win32.exe" 2> /dev/null
        create_installer "$TITLE-win32"
        mv "$IDENTITY-setup.exe" "$IDENTITY-setup-win32.exe"
    else
        zip -FS -9 -qr "$TITLE-win32.zip" "$TITLE-win32"
    fi
    rm -rf "$TITLE-win32"
fi

## Windows 64-bits ##
if [[ $X64 == true ]] && compare_version "$LOVE_VERSION" '>=' '0.8.0'; then

    if [[ ! -f "$CACHE_DIR/love-$LOVE_VERSION-win64.zip" ]]; then
        if compare_version "$LOVE_VERSION" '>=' '0.9.0'; then
            curl -L -C - -o "$CACHE_DIR/love-$LOVE_VERSION-win64.zip" https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win64.zip
        else
            curl -L -C - -o "$CACHE_DIR/love-$LOVE_VERSION-win-x64.zip" https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-win-x64.zip
        fi
    fi

    unzip -qq "$CACHE_DIR/love-$LOVE_VERSION-win64.zip"

    if [[ -n $ICON ]]; then
        WINEPREFIX="$WINEPREFIX" wine "$RESHACKER" \
            -addoverwrite "love-$LOVE_VERSION-win64/love.exe,love-$LOVE_VERSION-win64/love.exe,$ICON,ICONGROUP,MAINICON,0" 2> /dev/null
    fi

    cat love-$LOVE_VERSION-win64/love.exe "$LOVE_FILE" > "love-$LOVE_VERSION-win64/${TITLE}.exe"
    rm love-$LOVE_VERSION-win64/love.exe
    mv love-$LOVE_VERSION-win64 "$TITLE-win64"
    if [[ $INSTALLER == true ]]; then
        rm -rf "$IDENTITY-setup-win64.exe" 2> /dev/null
        create_installer "$TITLE-win64" "true"
        mv "$IDENTITY-setup.exe" "$IDENTITY-setup-win64.exe"
    else
        zip -FS -9 -qr "$TITLE-win64.zip" "$TITLE-win64"
    fi
    rm -rf "$TITLE-win64"
fi


exit_module

