#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "This script must be run as root, or you can change the installation directories by editing it." >&2
    exit 1
fi

echo "Installing..."

BINARY_DIR=/usr/bin
INSTALL_DIR=/usr/share/love-release
MANPAGE_DIR=/usr/share/man/man1

mkdir -p "$BINARY_DIR"
cp ./love-release.sh "$BINARY_DIR"/love-release
SED_ARG=s/INSTALL_DIR=/INSTALL_DIR=${INSTALL_DIR//\//\\\/}/g
sed -i -e "$SED_ARG" "$BINARY_DIR"/love-release

mkdir -p "$INSTALL_DIR"
cp ./README.md "$INSTALL_DIR"
cp -r ./scripts "$INSTALL_DIR"
cp -r ./include "$INSTALL_DIR"

mkdir -p "$MANPAGE_DIR"
cp love-release.1 "$MANPAGE_DIR"/love-release.1
sed -i -e "s/scripts/${INSTALL_DIR//\//\\\/}\/scripts/g" "$MANPAGE_DIR"/love-release.1
gzip -9 "$MANPAGE_DIR"/love-release.1

echo "Done !"

