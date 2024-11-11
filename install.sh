#!/bin/bash
set -e

CONF_DIR="/etc/byedpi"
BIN_DIR="/usr/local/bin"

GREEN="\033[0;32m"
NC="\033[0m"


TMP_DIR=$( mktemp -d )
if [[ ! -d $TMP_DIR ]]; then
    printf "[!] Failed to initialize temporary directory.\n"
    exit 1
fi
trap 'rm -rf -- "$TMP_DIR" && echo "Temporary directory $TMP_DIR wiped."' EXIT

printf "\n${GREEN}Preparing...${NC}\n"
mkdir -vp "$CONF_DIR"
id -u byedpi &>/dev/null || useradd -r -s /bin/false byedpi

printf "\n${GREEN}Downloading dependencies...${NC}\n"
curl -L -o "$TMP_DIR/ciadpi.tar.gz" \
    "https://github.com/hufrea/byedpi/releases/download/v0.15/byedpi-15-x86_64.tar.gz"
cd "$TMP_DIR"
tar zxvf "ciadpi.tar.gz"
find -type f -name "ciadpi-*" -exec mv -vf {} $BIN_DIR/ciadpi \;
cd -
chmod +x "$BIN_DIR/ciadpi"

curl -L -o "$BIN_DIR/hev-socks5-tunnel" \
    "https://github.com/heiher/hev-socks5-tunnel/releases/download/2.7.4/hev-socks5-tunnel-linux-x86_64"
chmod +x "$BIN_DIR/hev-socks5-tunnel"

printf "\n${GREEN}Installing...${NC}\n"
cp -v hev-socks5-tunnel.yaml "$CONF_DIR"
cp -v byedpictl.sh "$BIN_DIR/byedpictl"

printf "\n${GREEN}Installation complete.${NC}\n"
printf "Access by calling:\n    $ byedpictl help\n"
