#!/bin/bash
set -e

NAME="byedpictl"
BIN_DIR="/usr/local/bin"
CONF_DIR="/etc/$NAME"
LOG_DIR="/var/log/$NAME"
PID_DIR="/var/run/$NAME"

CLI_LOG="$LOG_DIR/cli.log"


cmd_help () {
    cat <<EOF
$0

COMMANDS:
    tun <start|stop|restart|status>
        Control and monitor the background routing to tunnel all traffic
        through the byedpi proxy.
    zenity
        Start in GUI mode.
    help
        Show this message and exit.
EOF
}

cmd_tun () {
    case $1 in
        start)
            start_tunneling
            ;;
        stop)
            stop_tunneling
            ;;
        restart)
            stop_tunneling
            start_tunneling
            ;;
        status)
            show_tunneling_status
            ;;
        *)
            echo "Invalid argument!"
    esac
}

cmd_zenity () {
    cmd=$(
        zenity --list --title="$NAME" --hide-header --column="0" \
        "Tunnel - Start" "Tunnel - Stop"
    )

    reply=""
    case $cmd in
        "Tunnel - Start")
            reply=$(pkexec "$0" tun start) || true
            ;;
        "Tunnel - Stop")
            reply=$(pkexec "$0" tun stop) || true
            ;;
    esac

    zenity --notification --title "$NAME" \
        --text="$reply"
}

prepare_dirs () {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
}

load_conf () {
    source "$CONF_DIR/server.conf"
    source "$CONF_DIR/desync.conf"
}

start_tunneling() {
    if [[ -f $PID_DIR/tunnel.pid ]]; then
        echo "Tunnel is already running"
        exit 1
    fi

    prepare_dirs
    load_conf


    ciadpi_args="--ip $CIADPI_IP --port $CIADPI_PORT ${CIADPI_DESYNC[@]}"

    nohup su - byedpi -s /bin/bash -c "$BIN_DIR/ciadpi $ciadpi_args" \
        > $LOG_DIR/server.log 2>&1 & echo $! > $PID_DIR/server.pid
    nohup $BIN_DIR/hev-socks5-tunnel $CONF_DIR/hev-socks5-tunnel.yaml \
        > $LOG_DIR/tunnel.log 2>&1 & echo $! > $PID_DIR/tunnel.pid

   while true; do
        sleep 0.2
        if ip tuntap list | grep -q byedpi-tun; then
            break
        fi

        echo "Waiting for tunnel interface..."
    done

    user_id=$(id -u byedpi)
    nic_name=$(ip route show to default | awk '$5 != "byedpi-tun" {print $5; exit}')
    gateway_addr=$(ip route show to default | awk '$5 != "byedpi-tun" {print $3; exit}')

    ip rule add uidrange $user_id-$user_id lookup 110 pref 28000
    ip route add default via $gateway_addr dev $nic_name metric 50 table 110
    ip route add default via 172.20.0.1 dev byedpi-tun metric 1

    echo "Successfully started the full traffic tunneling"
}

stop_tunneling () {
    if [[ ! -f $PID_DIR/tunnel.pid ]]; then
        echo "Tunnel is not running"
        exit 1
    fi

    user_id=$(id -u byedpi)
    nic_name=$(ip route show to default | awk '$5 != "byedpi-tun" {print $5; exit}')
    gateway_addr=$(ip route show to default | awk '$5 != "byedpi-tun" {print $3; exit}')

    ip rule del uidrange $user_id-$user_id lookup 110 pref 28000 2>$CLI_LOG || true
    ip route del default via "$gateway_addr" dev "$nic_name" metric 50 table 110 2>$CLI_LOG || true
    ip route del default via 172.20.0.1 dev byedpi-tun metric 1 2>$CLI_LOG || true

    kill $(cat $PID_DIR/tunnel.pid) 2>$CLI_LOG || true
    kill $(cat $PID_DIR/server.pid) 2>$CLI_LOG || true

    rm -rf "$PID_DIR" || true

    echo "Successfully stopped the tunneling"
}

show_tunneling_status () {
    server_status="offline"
    tun_status="offline"

    if [ -f "$PID_DIR/server.pid" ]; then
        if ps -p $(cat "$PID_DIR/server.pid") > /dev/null 2>&1; then
            server_status="running"
        else
            server_status="crashed"
        fi
    fi

    if [ -f "$PID_DIR/tunnel.pid" ]; then
        if ps -p $(cat "$PID_DIR/tunnel.pid") > /dev/null 2>&1; then
            tun_status="running"
        else
            tun_status="crashed"
        fi
    fi

    cat <<EOF
$NAME background tunneling services

server: $server_status
tunnel: $tun_status
EOF
}

case $1 in
    help)
        cmd_help
        ;;
    tun)
        cmd_tun $2
        ;;
    zenity)
        cmd_zenity
        ;;
    *)
        echo "Invalid argument $1"
        echo "Use \"help\" command."
        exit 1
esac
