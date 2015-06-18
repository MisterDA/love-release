# Debian package
init_module "Debian" "debian" "d"
OPTIONS="d"
LONG_OPTIONS=""


PACKAGE_NAME=$(echo $PROJECT_NAME | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')

# Configuration
if [ "$CONFIG" =  true ]; then
    if [ -n "${INI__debian__package_version}" ]; then
        PACKAGE_VERSION=${INI__debian__package_version}
    fi
    if [ -n "${INI__debian__maintainer_name}" ]; then
        MAINTAINER_NAME=${INI__debian__maintainer_name}
    fi
    if [ -n "${INI__debian__maintainer_email}" ]; then
        MAINTAINER_EMAIL=${INI__debian__maintainer_email}
    fi
    if [ -n "${INI__debian__package_name}" ]; then
        PACKAGE_NAME=${INI__debian__package_name}
    fi
    if [ -n "${INI__debian__icon}" ]; then
        ICON_DIR=${INI__debian__icon}
    fi
fi


# Options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "deb-package-version" ]; then
        PACKAGE_VERSION=$OPTARG
    elif [ "$OPTOPT" = "deb-maintainer-name" ]; then
        MAINTAINER_NAME=$OPTARG
    elif [ "$OPTOPT" = "maintainer-email" ]; then
        MAINTAINER_EMAIL=$OPTARG
    elif [ "$OPTOPT" = "deb-package-name" ]; then
        PACKAGE_NAME=$OPTARG
    elif [ "$OPTOPT" = "deb-icon" ]; then
        ICON_DIR=$OPTARG
    fi
done


# Debian
MISSING_INFO=0
ERROR_MSG="Could not build Debian package."
if [ -z "$PACKAGE_VERSION" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing project's version. Use --deb-package-version."
fi
if [ -z "$PROJECT_HOMEPAGE" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing project's homepage. Use --homepage."
fi
if [ -z "$PROJECT_DESCRIPTION" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing project's description. Use --description."
fi
if [ -z "$MAINTAINER_NAME" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing maintainer's name. Use --deb-maintainer-name."
fi
if [ -z "$MAINTAINER_EMAIL" ]; then
    MISSING_INFO=1
    ERROR_MSG="$ERROR_MSG\nMissing maintainer's email. Use --maintainer-email."
fi
if [ "$MISSING_INFO" -eq 1  ]; then
    exit_module "$MISSING_INFO" "$ERROR_MSG"
fi


create_love_file 9


TEMP=$(mktemp -d)

CONTROL=$TEMP/DEBIAN/control
mkdir -p $TEMP/DEBIAN
echo "Package: $PACKAGE_NAME"    >  $CONTROL
echo "Version: $PACKAGE_VERSION" >> $CONTROL
echo "Architecture: all"         >> $CONTROL
echo "Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>" >> $CONTROL
echo "Installed-Size: $(echo "$(stat -c %s "$PROJECT_NAME".love) / 1024" | bc)" >> $CONTROL
echo "Depends: love (>= $LOVE_VERSION)"   >> $CONTROL
echo "Priority: extra"                    >> $CONTROL
echo "Homepage: $PROJECT_HOMEPAGE"        >> $CONTROL
echo "Description: $PROJECT_DESCRIPTION"  >> $CONTROL
chmod 0644 $CONTROL

DESKTOP=$TEMP/usr/share/applications/${PACKAGE_NAME}.desktop
mkdir -p $TEMP/usr/share/applications
echo "[Desktop Entry]"              >  $DESKTOP
echo "Name=$PROJECT_NAME"           >> $DESKTOP
echo "Comment=$PROJECT_DESCRIPTION" >> $DESKTOP
echo "Exec=$PACKAGE_NAME"           >> $DESKTOP
echo "Type=Application"             >> $DESKTOP
echo "Categories=Game;"             >> $DESKTOP
chmod 0644 $DESKTOP

PACKAGE_DIR=$TEMP/usr/share/games/$PACKAGE_NAME
PACKAGE_LOC=$PACKAGE_NAME-$PACKAGE_VERSION.love

mkdir -p $PACKAGE_DIR
cp "$LOVE_FILE" $PACKAGE_DIR/$PACKAGE_LOC
chmod 0644 $PACKAGE_DIR/$PACKAGE_LOC

BIN_LOC=$TEMP/usr/bin
mkdir -p $BIN_LOC
echo "#!/usr/bin/env bash" >  $BIN_LOC/$PACKAGE_NAME
echo "set -e"              >> $BIN_LOC/$PACKAGE_NAME
echo "love /usr/share/games/$PACKAGE_NAME/$PACKAGE_LOC" >> $BIN_LOC/$PACKAGE_NAME
chmod 0755 $BIN_LOC/$PACKAGE_NAME

ICON_LOC=$TEMP/usr/share/icons/hicolor
mkdir -p $ICON_LOC
if [ -n "$ICON_DIR" ]; then
    echo "Icon=$PACKAGE_NAME" >> $DESKTOP

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
        if [ "$EXT" = "svg" ]; then
            mkdir -p $ICON_LOC/scalable/apps
            cp "$ICON_DIR"/"$ICON" $ICON_LOC/scalable/apps/${PACKAGE_NAME}.$EXT
            chmod 0644 $ICON_LOC/scalable/apps/${PACKAGE_NAME}.$EXT
        else
            if [ -n "$RES" ]; then
                mkdir -p $ICON_LOC/$RES/apps
                cp "$ICON_DIR"/"$ICON" $ICON_LOC/$RES/apps/${PACKAGE_NAME}.$EXT
                chmod 0644 $ICON_LOC/$RES/apps/${PACKAGE_NAME}.$EXT
            fi
        fi
    done
else
    echo "Icon=love" >> $DESKTOP
fi


cd $TEMP
for line in $(find usr/ -type f); do
    md5sum "$line" >> $TEMP/DEBIAN/md5sums
done
chmod 0644 $TEMP/DEBIAN/md5sums

for line in $(find usr/ -type d); do
    chmod 0755 "$line"
done

fakeroot dpkg-deb -b $TEMP "$RELEASE_DIR"/$PACKAGE_NAME-${PACKAGE_VERSION}_all.deb
cd "$RELEASE_DIR"
rm -rf $TEMP


unset MAINTAINER_NAME MAINTAINER_EMAIL PACKAGE_NAME PACKAGE_VERSION
exit_module

