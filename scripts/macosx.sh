# Mac OS X
execute_module "osx"

init_module "Mac OS X"


PACKAGE_NAME=$(echo $PROJECT_NAME | sed -e 's/[^-a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')

# Configuration
if [ "$CONFIG" = true ]; then
    if [ -n "${INI__macosx__maintainer_name}" ]; then
        MAINTAINER_NAME=${INI__macosx__maintainer_name}
    fi
    if [ -n "${INI__macosx__icon}" ]; then
        PROJECT_ICNS=${INI__macosx__icon}
    fi
fi


# Options
while getoptex "$SCRIPT_ARGS" "$@"
do
    if [ "$OPTOPT" = "osx-icon" ]; then
        PROJECT_ICNS=$OPTARG
    elif [ "$OPTOPT" = "osx-maintainer-name" ]; then
        MAINTAINER_NAME=$OPTARG
    fi
done


create_love_file 9


# Info.plist
## TODO: Remove this and replace it by parsing the file instead of overwriting
INFO_PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>13D65</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeIconFile</key>
			<string>LoveDocument.icns</string>
			<key>CFBundleTypeName</key>
			<string>LÖVE Project</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>org.love2d.love-game</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Folder</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>fold</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>None</string>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>love</string>
	<key>CFBundleIconFile</key>
	<string>${PROJECT_ICNS##/*/}</string>
	<key>CFBundleIdentifier</key>
	<string>org.$MAINTAINER_NAME.$PACKAGE_NAME</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$PROJECT_NAME</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$LOVE_VERSION</string>
	<key>CFBundleSignature</key>
	<string>LoVe</string>
	<key>DTCompiler</key>
	<string>com.apple.compilers.llvm.clang.1_0</string>
	<key>DTPlatformBuild</key>
	<string>5B1008</string>
	<key>DTPlatformVersion</key>
	<string>GM</string>
	<key>DTSDKBuild</key>
	<string>13C64</string>
	<key>DTSDKName</key>
	<string>macosx10.9</string>
	<key>DTXcode</key>
	<string>0511</string>
	<key>DTXcodeBuild</key>
	<string>5B1008</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.games</string>
	<key>NSHumanReadableCopyright</key>
	<string>© 2006-2014 LÖVE Development Team</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>"


## MacOS 64-bits ##
if [ "$LOVE_GT_090" = true ]; then
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip" ]; then
        cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    else
        curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-x64.zip
        cp $CACHE_DIR/love-$LOVE_VERSION-macosx-x64.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-x64.zip
    rm -rf "$PROJECT_NAME"-macosx-x64.zip 2> /dev/null
    mv love.app "$PROJECT_NAME".app
    cp "$PROJECT_NAME".love "$PROJECT_NAME".app/Contents/Resources
    cp "$PROJECT_ICNS" "$PROJECT_NAME".app/Contents/Resources 2> /dev/null

    echo "$INFO_PLIST" > "$PROJECT_NAME".app/Contents/Info.plist

    zip -9 -qyr "$PROJECT_NAME"-macosx-x64.zip "$PROJECT_NAME".app
    rm -rf love-$LOVE_VERSION-macosx-x64.zip "$PROJECT_NAME".app __MACOSX

    ## MacOS 32-bits ##
else
    if [ -f "$CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip" ]; then
        cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    else
        curl -L -C - -o $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip https://bitbucket.org/rude/love/downloads/love-$LOVE_VERSION-macosx-ub.zip
        cp $CACHE_DIR/love-$LOVE_VERSION-macosx-ub.zip ./
    fi
    unzip -qq love-$LOVE_VERSION-macosx-ub.zip
    rm -rf "$PROJECT_NAME"-macosx-ub.zip 2> /dev/null
    mv love.app "$PROJECT_NAME".app
    cp "$PROJECT_NAME".love "$PROJECT_NAME".app/Contents/Resources
    cp "$PROJECT_ICNS" "$PROJECT_NAME".app/Contents/Resources 2> /dev/null

    echo "$INFO_PLIST" > "$PROJECT_NAME".app/Contents/Info.plist

    zip -9 -qyr "$PROJECT_NAME"-macosx-ub.zip "$PROJECT_NAME".app
    rm -rf love-$LOVE_VERSION-macosx-ub.zip "$PROJECT_NAME".app __MACOSX
fi


unset PROJECT_ICNS
exit_module

