# Mac OS X
init_module "Mac OS X" "osx" "M"
OPTIONS="M"
LONG_OPTIONS=""


IDENTITY=$(echo $TITLE | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')

if [[ -z $AUTHOR ]]; then
    exit_module "options" "Missing maintainer's name. Use -a or --Mauthor."
fi
if [[ -z $GAME_VERSION ]]; then
    GAME_VERSION="$LOVE_VERSION"
fi

if [[ -n $ICON ]]; then
    if [[ -d $ICON ]]; then
        for file in $ICON/*.icns; do
            if [[ -f $file ]]; then
                ICON="$file"
                break
            else
                found=false
            fi
        done
    fi
    if [[ $found == false || ! -f $ICON ]]; then
        >&2 echo "OS X icon was not found in ${ICON}."
        icon=Love.icns
        ICON=
    else
        icon="${IDENTITY}.icns"
    fi
fi


create_love_file 9
cd "$RELEASE_DIR"


## MacOS 64-bits ##
if compare_version "$LOVE_VERSION" '>=' '0.9.0'; then
    if [[ ! -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip" ]]; then
        curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-x64.zip
    fi
    unzip -qq "$CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip"

    rm -rf "$TITLE-macosx-x64.zip" 2> /dev/null
    mv love.app "${TITLE}.app"
    cp "$LOVE_FILE" "${TITLE}.app/Contents/Resources"
    if [[ -n $ICON ]]; then
        cd "$PROJECT_DIR"
        cp "$ICON" "$RELEASE_DIR/$icon"
        cd "$RELEASE_DIR"
        mv "$icon" "${TITLE}.app/Contents/Resources"
    fi

    sed -i.bak -e '/<key>UTExportedTypeDeclarations<\/key>/,/^\t<\/array>/d' \
        -e "s/>org.love2d.love</>org.${AUTHOR}.$IDENTITY</" \
        -e "s/$LOVE_VERSION/$GAME_VERSION/" \
        -e "s/Love.icns/$icon/" \
        -e "s/>LÖVE</>$TITLE</" \
        "${TITLE}.app/Contents/Info.plist"
    rm "${TITLE}.app/Contents/Info.plist.bak"

    zip -9 -qyr "${TITLE}-macosx-x64.zip" "${TITLE}.app"
    rm -rf love-$LOVE_VERSION-macosx-x64.zip "${TITLE}.app" __MACOSX

    ## MacOS 32-bits ##
else
    if [[ ! -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip" ]]; then
        curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-ub.zip
    fi
    unzip -qq "$CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip"

    rm -rf "$TITLE-macosx-ub.zip" 2> /dev/null
    mv love.app "${TITLE}.app"
    cp "$LOVE_FILE" "${TITLE}.app/Contents/Resources"
    if [[ -n $ICON ]]; then
        cd "$PROJECT_DIR"
        cp "$ICON" "$RELEASE_DIR/$icon"
        cd "$RELEASE_DIR"
        mv "$icon" "${TITLE}.app/Contents/Resources"
    fi

    sed -i.bak -e '/<key>UTExportedTypeDeclarations<\/key>/,/^\t<\/array>/d' \
        -e "s/>org.love2d.love</>org.${AUTHOR}.$IDENTITY</" \
        -e "s/$LOVE_VERSION/$GAME_VERSION/" \
        -e "s/Love.icns/$icon/" \
        -e "s/>LÖVE</>$TITLE</" \
        "${TITLE}.app/Contents/Info.plist"
    rm "${TITLE}.app/Contents/Info.plist.bak"

    zip -9 -qyr "${TITLE}-macosx-ub.zip" "${TITLE}.app"
    rm -rf love-$LOVE_VERSION-macosx-ub.zip "${TITLE}.app" __MACOSX
fi


exit_module

