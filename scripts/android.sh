# Android debug package
init_module "Android"


PACKAGE_NAME=$(echo $PROJECT_NAME | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')
ACTIVITY=$(echo $PROJECT_NAME | sed -e 's/[^a-zA-Z0-9_]/_/g')

# Configuration
if [ "$CONFIG" = true ]; then
    if [ -n "${INI__android__activity}" ]; then
        ACTIVITY=${INI__android__activity}
    fi
    if [ -n "${INI__android__package_name}" ]; then
        PACKAGE_NAME=${INI__android__package_name}
    fi
    if [ -n "${INI__android__package_version}" ]; then
        PACKAGE_VERSION=${INI__android__package_version}
    fi
    if [ -n "${INI__android__maintainer_name}" ]; then
        MAINTAINER_NAME=${INI__android__maintainer_name}
    fi
    if [ -n "${INI__android__icon}" ]; then
        ICON_DIR=${INI__android__icon}
    fi
fi


# Options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "apk-activity" ]; then
        ACTIVITY=$OPTARG
        activity_defined_argument=true
    elif [ "$OPTOPT" = "apk-icon" ]; then
        ICON_DIR=$OPTARG
    elif [ "$OPTOPT" = "apk-package-version" ]; then
        PACKAGE_VERSION=$OPTARG
    elif [ "$OPTOPT" = "apk-maintainer-name" ]; then
        MAINTAINER_NAME=$OPTARG
    elif [ "$OPTOPT" = "apk-package-name" ]; then
        PACKAGE_NAME=$OPTARG
        package_name_defined_argument=true
    elif [ "$OPTOPT" = "update-android" ]; then
        UPDATE_ANDROID_REPO=true
    fi
done


# Android
MISSING_INFO=0
ERROR_MSG="Could not build Android package."
if [ -z "$PACKAGE_VERSION" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG
    Missing project's version. Use --apk-package-version."
fi
if [ -z "$MAINTAINER_NAME" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG
    Missing maintainer's name. Use --apk-maintainer-name."
fi
if [ "$MISSING_INFO" -eq 1  ]; then
    exit_module "$MISSING_INFO" "$ERROR_MSG"
fi


create_love_file 0


LOVE_ANDROID_DIR="$CACHE_DIR"/love-android-sdl2
if [ -d "$LOVE_ANDROID_DIR" ]; then
    cd "$LOVE_ANDROID_DIR"
    git checkout -- .
    rm -rf src/com bin gen
    if [ "$UPDATE_ANDROID_REPO" = true ]; then
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})
        BASE=$(git merge-base @ @{u})
        if [ $LOCAL = $REMOTE ]; then
            echo "love-android-sdl2 is already up-to-date."
        elif [ $LOCAL = $BASE ]; then
            git pull
            ndk-build --jobs $(( $(nproc) + 1))
        fi
    fi
    cd "$RELEASE_DIR"
else
    cd "$CACHE_DIR"
    git clone https://bitbucket.org/MartinFelis/love-android-sdl2.git
    cd "$LOVE_ANDROID_DIR"
    ndk-build --jobs $(( $(nproc) + 1))
    cd "$RELEASE_DIR"
fi

ANDROID_VERSION=$(grep -Eo -m 1 "[0-9]+.[0-9]+.[0-9]+[a-z]*" "$LOVE_ANDROID_DIR"/AndroidManifest.xml)
ANDROID_LOVE_VERSION=$(echo "$ANDROID_VERSION" | grep -Eo "[0-9]+.[0-9]+.[0-9]+")

if [ "$LOVE_VERSION" != "$ANDROID_LOVE_VERSION" ]; then
    exit_module 1 "Love version ($LOVE_VERSION) differs from love-android-sdl2 version ($ANDROID_LOVE_VERSION). Could not create package."
fi

mkdir -p "$LOVE_ANDROID_DIR"/assets
cp "$LOVE_FILE" "$LOVE_ANDROID_DIR"/assets/game.love
cd "$LOVE_ANDROID_DIR"
sed -i "s/org.love2d.android/com.${MAINTAINER_NAME}.${PACKAGE_NAME}/" AndroidManifest.xml
sed -i "s/$ANDROID_VERSION/${ANDROID_VERSION}-${PACKAGE_NAME}-v${PACKAGE_VERSION}/" AndroidManifest.xml
sed -i "0,/LÖVE for Android/s//$PROJECT_NAME $PACKAGE_VERSION/" AndroidManifest.xml
sed -i "s/LÖVE for Android/$PROJECT_NAME/" AndroidManifest.xml
sed -i "s/GameActivity/$ACTIVITY/" AndroidManifest.xml

mkdir -p src/com/$MAINTAINER_NAME/$PACKAGE_NAME
echo "package com.${MAINTAINER_NAME}.${PACKAGE_NAME};
import org.love2d.android.GameActivity;

public class $ACTIVITY extends GameActivity {}
" > src/com/$MAINTAINER_NAME/$PACKAGE_NAME/${ACTIVITY}.java

if [ -n "$ICON_DIR" ]; then

    IFS=$'\n'
    if [ "${ICON_DIR%?}" = "/" ]; then
        ICON_DIR=${ICON_DIR: -1}
    fi
    if [ "${ICON_DIR:0:1}" != "/" ]; then
        ICON_DIR=$PROJECT_DIR/$ICON_DIR
    fi
    ICON_FILES=( $(ls -AC1 "$ICON_DIR") )

    for ICON in "${ICON_FILES[@]}"
    do
        RES=$(echo "$ICON" | grep -Eo "[0-9]+x[0-9]+")
        EXT=$(echo "$ICON" | sed -e 's/.*\.//g')
        if [ "$RES" = "42x42" ]; then
            cp "$PROJECT_DIR"/"$ICON_DIR"/"$ICON" \
                "$LOVE_ANDROID_DIR"/res/drawable-mdpi/ic_launcher.png
        elif [ "$RES" = "72x72" ]; then
            cp "$PROJECT_DIR"/"$ICON_DIR"/"$ICON" \
                "$LOVE_ANDROID_DIR"/res/drawable-hdpi/ic_launcher.png
        elif [ "$RES" = "96x96" ]; then
            cp "$PROJECT_DIR"/"$ICON_DIR"/"$ICON" \
                "$LOVE_ANDROID_DIR"/res/drawable-xhdpi/ic_launcher.png
        elif [ "$RES" = "144x144" ]; then
            cp "$PROJECT_DIR"/"$ICON_DIR"/"$ICON" \
                "$LOVE_ANDROID_DIR"/res/drawable-xxhdpi/ic_launcher.png
        elif [ "$RES" = "732x412" ]; then
            cp "$PROJECT_DIR"/"$ICON_DIR"/"$ICON" \
                "$LOVE_ANDROID_DIR"/res/drawable-xhdpi/ouya_icon.png
        fi
    done
    if [ -f "$PROJECT_DIR/$ICON_DIR/drawable-mdpi/ic_launcher.png" ]; then
        cp "$PROJECT_DIR"/"$ICON_DIR"/drawable-mdpi/ic_launcher.png \
            "$LOVE_ANDROID_DIR"/res/drawable-mdpi/ic_launcher.png
    fi
    if [ -f "$PROJECT_DIR/$ICON_DIR/drawable-hdpi/ic_launcher.png" ]; then
        cp "$PROJECT_DIR"/"$ICON_DIR"/drawable-hdpi/ic_launcher.png \
            "$LOVE_ANDROID_DIR"/res/drawable-hdpi/ic_launcher.png
    fi
    if [ -f "$PROJECT_DIR/$ICON_DIR/drawable-xhdpi/ic_launcher.png" ]; then
        cp "$PROJECT_DIR"/"$ICON_DIR"/drawable-xhdpi/ic_launcher.png \
            "$LOVE_ANDROID_DIR"/res/drawable-xhdpi/ic_launcher.png
    fi
    if [ -f "$PROJECT_DIR/$ICON_DIR/drawable-xxhdpi/ic_launcher.png" ]; then
        cp "$PROJECT_DIR"/"$ICON_DIR"/drawable-xxhdpi/ic_launcher.png \
            "$LOVE_ANDROID_DIR"/res/drawable-xxhdpi/ic_launcher.png
    fi
    if [ -f "$PROJECT_DIR/$ICON_DIR/drawable-xhdpi/ouya_icon.png" ]; then
        cp "$PROJECT_DIR"/"$ICON_DIR"/drawable-xhdpi/ouya_icon.png \
            "$LOVE_ANDROID_DIR"/res/drawable-xhdpi/ouya_icon.png
    fi
fi


ant debug
cp bin/love_android_sdl2-debug.apk "$RELEASE_DIR"
git checkout -- .
rm -rf src/com bin gen
cd "$RELEASE_DIR"


unset ACTIVITY PACKAGE_NAME PACKAGE_VERSION MAINTAINER_NAME
exit_module

