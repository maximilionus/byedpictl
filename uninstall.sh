#!/bin/bash
set -e

CONF_DIR="/etc/byedpi"
BIN_DIR="/usr/local/bin"

GREEN="\033[0;32m"
NC="\033[0m"


printf "${GREEN}Begin uninstall...${NC}\n"
rm -rfv "$CONF_DIR"
rm -fv "$BIN_DIR/ciadpi"
rm -fv "$BIN_DIR/hev-socks5-tunnel"
id -u byedpi &>/dev/null && userdel byedpi

printf "\n${GREEN}Successfully uninstalled.${NC}\n"
