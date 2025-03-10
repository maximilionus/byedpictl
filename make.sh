#!/bin/bash
set -e

SRC_DIR="src"
CONF_DIR="/etc/byedpictl"
BIN_DIR="/usr/local/bin"

C_RESET="\e[0m"
C_BOLD="\e[1m"
C_GREEN="\e[0;32m"
C_RED="\e[0;31m"


cmd_help () {
    cat <<EOF
$0

COMMANDS:
    install
        Deploy the project files and dependencies.
    remove
        Uninstall the project.
    help
        Show this message and exit.
EOF
}

cmd_install () {
    tmp_dir=$( mktemp -d )
    if [[ ! -d $tmp_dir ]]; then
        printf "${C_RED}Failed to initialize temporary directory.${C_RESET}\n"
        exit 1
    fi
    trap 'rm -rf -- "$tmp_dir"' EXIT

    printf "${C_BOLD}Setting up${C_RESET}\n"
    target_arch=$( uname -m )
    mkdir -p "$CONF_DIR"
    id -u byedpi &>/dev/null || useradd -r -s /bin/false byedpi

    printf "${C_BOLD}- Downloading and preparing the dependencies${C_RESET}\n"
    printf -- "- Server\n"
    curl -L --progress-bar -o "$tmp_dir/ciadpi.tar.gz" \
        "https://github.com/hufrea/byedpi/releases/download/v0.16.6/byedpi-16.6-$target_arch.tar.gz"
    cd "$tmp_dir"
    tar -zxf "ciadpi.tar.gz"
    find -type f -name "ciadpi-*" -exec mv -f {} $BIN_DIR/ciadpi \;
    cd "$OLDPWD"
    chmod +x "$BIN_DIR/ciadpi"

    printf -- "- Tunnel\n"
    curl -L --progress-bar -o "$BIN_DIR/hev-socks5-tunnel" \
        "https://github.com/heiher/hev-socks5-tunnel/releases/download/2.9.1/hev-socks5-tunnel-linux-$target_arch"
    chmod +x "$BIN_DIR/hev-socks5-tunnel"

    printf "${C_BOLD}- Installing the main components${C_RESET}\n"
    cp "$SRC_DIR/hev-socks5-tunnel.yaml" "$CONF_DIR"
    cp "$SRC_DIR/server.conf" "$CONF_DIR"
    cp "$SRC_DIR/desync.conf" "$CONF_DIR"
    cp "$SRC_DIR/byedpictl.sh" "$BIN_DIR/byedpictl"


    printf "${C_GREEN}Installation complete${C_RESET}\n"
    cat <<EOF

Get basic usage information by executing
  $ byedpictl help

DPI desync parameters can be changed here
  $CONF_DIR/desync.conf
EOF
}

cmd_remove () {
    printf "${C_BOLD}Removal${C_RESET} "
    rm -rf "$CONF_DIR"
    rm -f "$BIN_DIR/byedpictl"
    rm -f "$BIN_DIR/ciadpi"
    rm -f "$BIN_DIR/hev-socks5-tunnel"
    id -u byedpi &>/dev/null && userdel byedpi

    printf "${C_GREEN}Done${C_RESET}\n"
}


[[ $( id -u ) != 0 ]] && \
    printf "${C_RED}Root required!${C_RESET}\n" && exit 1

case $1 in
    help)
        cmd_help
        ;;
    install)
        cmd_install
        ;;
    remove)
        cmd_remove
        ;;
    *)
        printf "${C_RED}Invalid argument${C_RESET} $1\n"
        printf "Use ${C_BOLD}help${C_RESET} command\n"
        exit 1
esac
