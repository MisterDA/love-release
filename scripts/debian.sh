# Debian package
init_module "Debian" "debian" "D"
MOD_OPTIONS="D"
MOD_LONG_OPTIONS=""


IDENTITY=$(echo $TITLE | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')

# Debian
missing_info=false
error_msg="Could not build Debian package."
if [[ -z $GAME_VERSION ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing project's version. Use -v or --Dversion."
fi
if [[ -z $URL ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing project's homepage. Use -u or -Durl."
fi
if [[ -z $DESCRIPTION ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing project's description. Use -d or --Ddescription."
fi
if [[ -z $AUTHOR ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing maintainer's name. Use -a or --Dauthor."
fi
if [[ -z $EMAIL ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing maintainer's email. Use -e or --Demail."
fi
if [[ $missing_info == true  ]]; then
    exit_module "options" "$error_msg"
fi


create_love_file 9
cd "$RELEASE_DIR"


TEMP="$(mktemp -d)"
umask 0022

mkdir -p "$TEMP/DEBIAN"
cat > "$TEMP/DEBIAN/control" <<EOF
Package: $IDENTITY
Version: $GAME_VERSION
Architecture: all
Maintainer: $AUTHOR <$EMAIL>
Installed-Size: $(( $(stat -c %s "$LOVE_FILE") / 1024 ))
Depends: love (>= $LOVE_VERSION)
Priority: extra
Homepage: $URL
Description: $DESCRIPTION
EOF

mkdir -p "$TEMP/usr/share/applications"
cat > "$TEMP/usr/share/applications/${IDENTITY}.desktop" <<EOF
[Desktop Entry]
Name=$TITLE
Comment=$DESCRIPTION
Exec=$IDENTITY
Type=Application
Categories=Game;
EOF

mkdir -p "$TEMP/usr/bin"
cat <(echo -ne '#!/usr/bin/env love\n') "$LOVE_FILE" > "$TEMP/usr/bin/$IDENTITY"
chmod +x "$TEMP/usr/bin/$IDENTITY"

if [[ -d $ICON ]]; then
    ICON_LOC=$TEMP/usr/share/icons/hicolor
    mkdir -p $ICON_LOC
    echo "Icon=$IDENTITY" >> "$TEMP/usr/share/applications/${IDENTITY}.desktop"

    cd "$ICON"
    for file in *; do
        RES=$(echo "$file" | grep -Eo "[0-9]+x[0-9]+")
        EXT=$(echo "$file" | sed -e 's/.*\.//g')
        if [[ $EXT == "svg" ]]; then
            mkdir -p "$ICON_LOC/scalable/apps"
            cp "$file" "$ICON_LOC/scalable/apps/${IDENTITY}.svg"
            chmod 0644 "$ICON_LOC/scalable/apps/${IDENTITY}.svg"
        elif [[ -n $RES ]]; then
            mkdir -p "$ICON_LOC/$RES/apps"
            cp "$file" "$ICON_LOC/$RES/apps/${IDENTITY}.$EXT"
            chmod 0644 "$ICON_LOC/$RES/apps/${IDENTITY}.$EXT"
        fi
    done
else
    echo "Icon=love" >> "$TEMP/usr/share/applications/${IDENTITY}.desktop"
fi

cd "$TEMP"
# TODO: There might be a problem here if the filename contains weird characters.
find "usr" -type f -exec md5sum {} \; | sed -E "s/^([0-9a-f]{32}  )/\1\//g" > "$TEMP/DEBIAN/md5sums"
cd "$PROJECT_DIR"

fakeroot dpkg-deb -b "$TEMP" "$RELEASE_DIR/$IDENTITY-${GAME_VERSION}_all.deb"
rm -rf "$TEMP"


exit_module
