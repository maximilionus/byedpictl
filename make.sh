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
    mkdir -vp "$CONF_DIR"
    id -u byedpi &>/dev/null || useradd -r -s /bin/false byedpi

    printf "${C_BOLD}Downloading and preparing the dependencies${C_RESET}\n"
    curl -L -o "$tmp_dir/ciadpi.tar.gz" \
        "https://github.com/hufrea/byedpi/releases/download/v0.16.1/byedpi-16.1-$target_arch.tar.gz"
    cd "$tmp_dir"
    tar -zxvf "ciadpi.tar.gz"
    find -type f -name "ciadpi-*" -exec mv -vf {} $BIN_DIR/ciadpi \;
    cd -
    chmod +x "$BIN_DIR/ciadpi"

    curl -L -o "$BIN_DIR/hev-socks5-tunnel" \
        "https://github.com/heiher/hev-socks5-tunnel/releases/download/2.7.5/hev-socks5-tunnel-linux-$target_arch"
    chmod +x "$BIN_DIR/hev-socks5-tunnel"

    printf "${C_BOLD}Installing the main components${C_RESET}\n"
    cp -v "$SRC_DIR/hev-socks5-tunnel.yaml" "$CONF_DIR"
    cp -v "$SRC_DIR/server.conf" "$CONF_DIR"
    cp -v "$SRC_DIR/desync.conf" "$CONF_DIR"
    cp -v "$SRC_DIR/byedpictl.sh" "$BIN_DIR/byedpictl"


    printf "${C_GREEN}Installation complete${C_RESET}\n"
    cat <<EOF

- Get basic usage information by executing
    $ byedpictl help

- DPI desync parameters can be changed here
    $CONF_DIR/desync.conf
EOF
}

cmd_remove () {
    printf "${C_BOLD}Removal${C_RESET}\n"
    rm -rfv "$CONF_DIR"
    rm -fv "$BIN_DIR/byedpictl"
    rm -fv "$BIN_DIR/ciadpi"
    rm -fv "$BIN_DIR/hev-socks5-tunnel"
    id -u byedpi &>/dev/null && userdel byedpi

    printf "\n${C_GREEN}Successfully uninstalled${C_RESET}\n"
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
