#!/bin/bash
set -e

SRC="src"
SRC_CONF="$SRC/conf"
SRC_BIN="$SRC/bin"
SRC_XDG="$SRC/xdg"
SRC_IMG="$SRC/img"
SRC_ICON="$SRC_IMG/icons"

CONF="/etc/byedpictl"
BIN="/usr/local/bin"

C_RESET="\e[0m"
C_BOLD="\e[1m"
C_GREEN="\e[0;32m"
C_RED="\e[0;31m"

download_dependencies () {
    local target_arch=$(uname -m)
    local tunnel_url="https://github.com/heiher/hev-socks5-tunnel/releases/download/2.14.3/hev-socks5-tunnel-linux-$target_arch"
    local server_url="https://github.com/hufrea/byedpi/releases/download/v0.17.3/byedpi-17.3-$target_arch.tar.gz"
    local tmp_dir=$(mktemp -d)

    if [[ ! -d $tmp_dir ]]; then
        printf "${C_RED}Failed to initialize temporary directory.${C_RESET}\n"
        exit 1
    fi
    trap 'rm -rf -- "$tmp_dir"' EXIT

    printf "${C_BOLD}- Downloading and preparing the dependencies${C_RESET}\n"
    printf -- "- Server\n"
    curl -L --progress-bar -o "$tmp_dir/ciadpi.tar.gz" "$server_url"
    cd "$tmp_dir"
    tar -zxf "ciadpi.tar.gz"
    #find -type f -name "ciadpi-*" -exec mv -f {} $BIN/ciadpi \;
    mv ciadpi-* "$BIN/ciadpi"
    chmod +x "$BIN/ciadpi"
    cd "$OLDPWD"

    printf -- "- Tunnel\n"
    curl -L --progress-bar -o "$BIN/hev-socks5-tunnel" "$tunnel_url"
    chmod +x "$BIN/hev-socks5-tunnel"
}

deploy_ctl () {
    printf "${C_BOLD}- Installing the control tool${C_RESET}\n"
    cp "$SRC_BIN/byedpictl.sh" "$BIN/byedpictl"
}

deploy_conf () {
    printf "${C_BOLD}- Installing the default configuration${C_RESET}\n"
    mkdir -p "$CONF"
    cp -r "$SRC_CONF"/* "$CONF"
}

deploy_xdg () {
    printf "${C_BOLD}- Installing the desktop integration${C_RESET}\n"
    mkdir -p /usr/share/desktop-directories # Fix xdg-utils dir discovery fail
    xdg-desktop-menu install --novendor "$SRC_XDG/byedpictl.desktop"
    xdg-icon-resource install --novendor --size 128 "$SRC_ICON/128/byedpictl.png"
}

cmd_help () {
    cat <<EOF
$0

COMMANDS
    install
        Install this project and download it's dependencies.
    update
        Update this project, leaving the configuration intact.
    remove
        Uninstall this project.
    help
        Show this message and exit.
EOF
}

cmd_install () {
    printf "${C_BOLD}Setting up${C_RESET}\n"
    id -u byedpi &>/dev/null || useradd -r -s /bin/false byedpi

    download_dependencies
    deploy_ctl
    deploy_conf
    deploy_xdg

    printf "\n${C_GREEN}Installation complete.${C_RESET}\n"
    cat <<EOF

Get basic usage information by executing
    $ byedpictl help

Update to the latest version without overwriting the configuration with
    $ $0 update

DPI desync parameters can be modified here
    $CONF/desync.conf
EOF
}

cmd_update () {
    printf "${C_BOLD}Updating main components${C_RESET}\n"
    download_dependencies
    deploy_ctl
    deploy_xdg

    printf "\n${C_GREEN}Update complete.${C_RESET}\nConfiguration is left intact.\n"
}

cmd_remove () {
    printf "${C_BOLD}Removal${C_RESET} "
    rm -rf "$CONF"
    rm -f "$BIN/byedpictl"
    rm -f "$BIN/ciadpi"
    rm -f "$BIN/hev-socks5-tunnel"
    id -u byedpi &>/dev/null && userdel byedpi
    xdg-desktop-menu uninstall "$SRC_XDG/byedpictl.desktop"
    xdg-icon-resource uninstall --size 128 "$SRC_ICON/128/byedpictl.png"

    printf "\n${C_GREEN}Removal complete.${C_RESET}\n"
}


[[ $( id -u ) != 0 ]] && \
    printf "${C_RED}Superuser required!${C_RESET}\n" && exit 1

case $1 in
    help)
        cmd_help
        ;;
    install)
        cmd_install
        ;;
    update)
        cmd_update
        ;;
    remove)
        cmd_remove
        ;;
    *)
        printf "${C_RED}Invalid argument.${C_RESET} $1\n"
        printf "Use ${C_BOLD}help${C_RESET} command.\n"
        exit 1
esac
