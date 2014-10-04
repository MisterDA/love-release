#!/usr/bin/env bash

if [ $UID -eq 0 ]; then
    read -n 1 -p "Do you wish to install love-release system-wide ? [Y/n]: " yn
    case $yn in
        [Yy]*|"" ) echo;;
        * ) echo -e "\nInstallation aborted."; exit;;
    esac

    echo "Installing..."
    BINARY_DIR=/usr/bin
    INSTALL_DIR=/usr/share/love-release
    MANPAGE_DIR=/usr/share/man/man1
    COMPLETION_DIR=$(pkg-config --variable=completionsdir bash-completion)
else
    read -n 1 -p "Do you wish to install love-release in your user directory ? [Y/n]: " yn
    case $yn in
        [Yy]*|"" ) echo;;
        * ) echo -e "\nInstallation aborted."; exit;;
    esac

    echo "Installing..."
    BINARY_DIR="$HOME"/bin
    INSTALL_DIR="$HOME"/.local/share/love-release
    MANPAGE_DIR="$HOME"/.local/share/man/man1
    COMPLETION_DIR="$HOME"/.bash_completion

    echo "Add these lines to your shell rc file:"
    echo "    export PATH=\"$BINARY_DIR:\$PATH\""
    echo "    export MANPATH=\"$MANPAGE_DIR:\""
fi


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

