# Android debug package
init_module "Android" "android" "A"
OPTIONS="A"
LONG_OPTIONS="activity:,update"


IDENTITY=$(echo $TITLE | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')
ACTIVITY=$(echo $TITLE | sed -e 's/[^a-zA-Z0-9_]/_/g')


# Options
while true; do
    case "$1" in
        --Aactivity ) ACTIVITY="$2"; shift 2 ;;
        --Aupdate )   UPDATE_ANDROID=true; shift ;;
        -- ) break ;;
        * ) shift ;;
    esac
done


# Android
missing_info=false
missing_deps=false
error_msg="Could not build Android package."
if ! command -v git > /dev/null 2>&1; then
    missing_deps=true
    error_msg="$error_msg\ngit was not found."
fi
if ! command -v ndk-build > /dev/null 2>&1; then
    missing_deps=true
    error_msg="$error_msg\nndk-build was not found."
fi
if ! command -v ant > /dev/null 2>&1; then
    missing_deps=true
    error_msg="$error_msg\nant was not found."
fi
if [[ $missing_deps == true  ]]; then
    exit_module "deps" "$error_msg"
fi

if [[ -z $GAME_VERSION ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing project's version. Use -v or --Aversion."
fi
if [[ -z $AUTHOR ]]; then
    missing_info=true
    error_msg="$error_msg\nMissing maintainer's name. Use -a or --Aauthor."
fi
if [[ $missing_info == true  ]]; then
    exit_module "options" "$error_msg"
fi


create_love_file 0


LOVE_ANDROID_DIR="$CACHE_DIR/love-android-sdl2"
if [[ -d $LOVE_ANDROID_DIR ]]; then
    cd "$LOVE_ANDROID_DIR"
    git checkout -- .
    rm -rf src/com bin gen
    if [[ $UPDATE_ANDROID = true ]]; then
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})
        BASE=$(git merge-base @ @{u})
        if [[ $LOCAL == $REMOTE ]]; then
            echo "love-android-sdl2 is already up-to-date."
        elif [[ $LOCAL == $BASE ]]; then
            git pull
            ndk-build --jobs $(( $(nproc) + 1))
        fi
    fi
else
    cd "$CACHE_DIR"
    git clone https://bitbucket.org/MartinFelis/love-android-sdl2.git
    cd "$LOVE_ANDROID_DIR"
    ndk-build --jobs $(( $(nproc) + 1))
fi

ANDROID_VERSION=$(grep -Eo -m 1 "[0-9]+.[0-9]+.[0-9]+[a-z]*" "$LOVE_ANDROID_DIR"/AndroidManifest.xml)
ANDROID_LOVE_VERSION=$(echo "$ANDROID_VERSION" | grep -Eo "[0-9]+.[0-9]+.[0-9]+")

if [[ "$LOVE_VERSION" != "$ANDROID_LOVE_VERSION" ]]; then
    exit_module 1 "Love version ($LOVE_VERSION) differs from love-android-sdl2 version ($ANDROID_LOVE_VERSION). Could not create package."
fi

mkdir -p assets
cd "$PROJECT_DIR"
cd "$RELEASE_DIR"
cp "$LOVE_FILE" "$LOVE_ANDROID_DIR/assets/game.love"
cd "$LOVE_ANDROID_DIR"

sed -i.bak -e "s/org.love2d.android/com.${AUTHOR}.${IDENTITY}/" \
    -e "s/$ANDROID_VERSION/${ANDROID_VERSION}-${IDENTITY}-v${GAME_VERSION}/" \
    -e "0,/LÖVE for Android/s//$TITLE $GAME_VERSION/" \
    -e "s/LÖVE for Android/$TITLE/" \
    -e "s/GameActivity/$ACTIVITY/" \
    AndroidManifest.xml

mkdir -p "src/com/$AUTHOR/$IDENTITY"
cat > "src/com/$AUTHOR/$IDENTITY/${ACTIVITY}.java" <<EOF
package com.${AUTHOR}.${IDENTITY};
import org.love2d.android.GameActivity;

public class $ACTIVITY extends GameActivity {}
EOF

if [[ -d "$ICON" ]]; then
    cd "$PROJECT_DIR"
    cd "$ICON"

    for icon in *; do
        RES=$(echo "$icon" | grep -Eo "[0-9]+x[0-9]+")
        EXT=$(echo "$icon" | sed -e 's/.*\.//g')
        if [[ $RES == "42x42" ]]; then
            cp "$icon" "$LOVE_ANDROID_DIR/res/drawable-mdpi/ic_launcher.png"
        elif [[ $RES == "72x72" ]]; then
            cp "$icon" "$LOVE_ANDROID_DIR/res/drawable-hdpi/ic_launcher.png"
        elif [[ $RES == "96x96" ]]; then
            cp "$icon" "$LOVE_ANDROID_DIR/res/drawable-xhdpi/ic_launcher.png"
        elif [[ $RES == "144x144" ]]; then
            cp "$icon" "$LOVE_ANDROID_DIR/res/drawable-xxhdpi/ic_launcher.png"
        elif [[ "$RES" == "732x412" ]]; then
            cp "$icon" "$LOVE_ANDROID_DIR/res/drawable-xhdpi/ouya_icon.png"
        fi
    done
    if [[ -f "drawable-mdpi/ic_launcher.png" ]]; then
        cp "drawable-mdpi/ic_launcher.png" "$LOVE_ANDROID_DIR/res/drawable-mdpi/ic_launcher.png"
    fi
    if [[ -f "drawable-hdpi/ic_launcher.png" ]]; then
        cp "drawable-hdpi/ic_launcher.png" "$LOVE_ANDROID_DIR/res/drawable-hdpi/ic_launcher.png"
    fi
    if [[ -f "drawable-xhdpi/ic_launcher.png" ]]; then
        cp "drawable-xhdpi/ic_launcher.png" "$LOVE_ANDROID_DIR/res/drawable-xhdpi/ic_launcher.png"
    fi
    if [[ -f "drawable-xxhdpi/ic_launcher.png" ]]; then
        cp "drawable-xxhdpi/ic_launcher.png" "$LOVE_ANDROID_DIR/res/drawable-xxhdpi/ic_launcher.png"
    fi
    if [[ -f "drawable-xhdpi/ouya_icon.png" ]]; then
        cp "drawable-xhdpi/ouya_icon.png" "$LOVE_ANDROID_DIR/res/drawable-xhdpi/ouya_icon.png"
    fi

    cd "$LOVE_ANDROID_DIR"
fi


ant debug
cd "$PROJECT_DIR"
cp "$LOVE_ANDROID_DIR/bin/love_android_sdl2-debug.apk" "$RELEASE_DIR"
git checkout -- .
rm -rf src/com bin gen


exit_module

