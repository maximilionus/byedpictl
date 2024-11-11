#!/bin/bash
set -e

CONF_DIR="/etc/byedpi"
BIN_DIR="/usr/local/bin"

TMP_DIR=$( mktemp -d )
if [[ ! -d $TMP_DIR ]]; then
    echo "[!] Failed to initialize temporary directory."
    exit 1
fi
trap 'rm -rf -- "$TMP_DIR" && echo "-> Temporary directory $TMP_DIR wiped."' EXIT

echo "-> Preparing"
mkdir -vp "$CONF_DIR"
id -u byedpi &>/dev/null || sudo useradd -r -s /bin/false byedpi

echo "-> Downloading dependencies"
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

echo "-> Installing"
cp -v hev-socks5-tunnel.yaml "$CONF_DIR"
cp -v byedpictl.sh "$BIN_DIR/byedpictl"
