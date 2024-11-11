#!/bin/bash
set -e

CONF_DIR="/etc/byedpi"
BIN_DIR="/usr/local/bin"


echo "Begin uninstall..."
rm -rfv "$CONF_DIR"
rm -fv "$BIN_DIR/ciadpi"
rm -fv "$BIN_DIR/hev-socks5-tunnel"
id -u byedpi &>/dev/null && userdel -r -s /bin/false byedpi

echo
echo "Successfully uninstalled"
