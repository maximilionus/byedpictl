#!/bin/bash
set -e

SRC_DIR="src"
CONF_DIR="/etc/byedpi"
BIN_DIR="/usr/local/bin"

GREEN="\e[0;32m"
RED="\e[0;31m"
NC="\e[0m"

target_arch=$( uname -m )


[[ $( id -u ) != 0 ]] && \
    printf "${RED}Root required!${NC}\n" && exit 1

TMP_DIR=$( mktemp -d )
if [[ ! -d $TMP_DIR ]]; then
    printf "${RED}Failed to initialize temporary directory.${NC}\n"
    exit 1
fi
trap 'rm -rf -- "$TMP_DIR" && echo "Temporary directory $TMP_DIR wiped."' EXIT

printf "Setting up\n"
mkdir -vp "$CONF_DIR"
id -u byedpi &>/dev/null || useradd -r -s /bin/false byedpi

printf "Downloading and preparing the dependencies\n"
curl -L -o "$TMP_DIR/ciadpi.tar.gz" \
    "https://github.com/hufrea/byedpi/releases/download/v0.15/byedpi-15-$target_arch.tar.gz"
cd "$TMP_DIR"
tar -zxvf "ciadpi.tar.gz"
find -type f -name "ciadpi-*" -exec mv -vf {} $BIN_DIR/ciadpi \;
cd -
chmod +x "$BIN_DIR/ciadpi"

curl -L -o "$BIN_DIR/hev-socks5-tunnel" \
    "https://github.com/heiher/hev-socks5-tunnel/releases/download/2.7.5/hev-socks5-tunnel-linux-$target_arch"
chmod +x "$BIN_DIR/hev-socks5-tunnel"

printf "Installing the main components\n"
cp -v "$SRC_DIR/hev-socks5-tunnel.yaml" "$CONF_DIR"
cp -v "$SRC_DIR/server.conf" "$CONF_DIR"
cp -v "$SRC_DIR/desync.conf" "$CONF_DIR"
cp -v "$SRC_DIR/byedpictl.sh" "$BIN_DIR/byedpictl"

printf "${GREEN}Installation complete${NC}\n"
printf "\nAccess by calling:\n    $ byedpictl help\n"
