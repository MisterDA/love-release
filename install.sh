#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "This script must be run as root, or you can change the installation directories by editing it." >&2
    exit 1
fi

echo "Installing..."

BINARY_DIR=/usr/bin
INSTALL_DIR=/usr/share/love-release
MANPAGE_DIR=/usr/share/man/man1
COMPLETION_DIR=/etc/bash_completion.d

SED_ARG=$(echo "$INSTALL_DIR" | sed -e 's/[\/&]/\\&/g')
mkdir -p "$BINARY_DIR"
sed -e "s/INSTALL_DIR=/INSTALL_DIR=$SED_ARG/g" love-release.sh > "$BINARY_DIR"/love-release
chmod +x "$BINARY_DIR"/love-release

mkdir -p "$INSTALL_DIR"
cp ./README.md "$INSTALL_DIR"
cp ./config.ini "$INSTALL_DIR"
cp -r ./scripts "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/include
_PWD=$PWD
if [ -d "$INSTALL_DIR"/include/getopt ]; then
    cd "$INSTALL_DIR"/include/getopt
    git pull
    cd "$_PWD"
else
    git clone https://gist.github.com/MisterDA/7284755 "$INSTALL_DIR"/include/getopt
fi
if [ -d "$INSTALL_DIR"/include/bash_ini_parser ]; then
    cd "$INSTALL_DIR"/include/bash_ini_parser
    git pull
    cd "$_PWD"
else
    git clone https://github.com/rudimeier/bash_ini_parser "$INSTALL_DIR"/include/bash_ini_parser
fi

mkdir -p "$MANPAGE_DIR"
sed -e "s/scripts/$SED_ARG\/scripts/g" -e "s/config.ini/$SED_ARG\/config.ini/g" love-release.1 > "$MANPAGE_DIR"/love-release.1
gzip -9 -f "$MANPAGE_DIR"/love-release.1

mkdir -p "$COMPLETION_DIR"
cp ./completion.sh "$COMPLETION_DIR"/love-release

echo "Done !"

