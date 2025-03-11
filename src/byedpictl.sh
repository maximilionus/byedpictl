#!/bin/bash
set -e

BIN_DIR="/usr/local/bin"
CONF_DIR="/etc/byedpictl"
LOG_DIR="/var/log/byedpictl"
PID_DIR="/var/run/byedpictl"


cmd_help () {
    cat <<EOF
$0

COMMANDS:
    tun <start|stop|restart|status>
        Control and monitor the background routing to tunnel all traffic
        through the byedpi proxy.
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

prepare_dirs () {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
}

load_conf () {
    source "$CONF_DIR/server.conf"
    source "$CONF_DIR/desync.conf"
}

start_tunneling() {
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
    if [[ ! -d $PID_DIR ]]; then
        echo "Tunnel is not running"
        exit 1
    fi

    user_id=$(id -u byedpi)
    nic_name=$(ip route show to default | awk '$5 != "byedpi-tun" {print $5; exit}')
    gateway_addr=$(ip route show to default | awk '$5 != "byedpi-tun" {print $3; exit}')

    # Not sure if that's a good idea to let all steps be passable by default
    # as this may lead to a lot of unexpected behavior. There should be at
    # least some "is command even available" checks here.

    ip rule del uidrange $user_id-$user_id lookup 110 pref 28000 2>/dev/null || true
    ip route del default via "$gateway_addr" dev "$nic_name" metric 50 table 110 2>/dev/null || true
    ip route del default via 172.20.0.1 dev byedpi-tun metric 1 2>/dev/null || true

    kill $(cat $PID_DIR/tunnel.pid) 2>/dev/null || true
    kill $(cat $PID_DIR/server.pid) 2>/dev/null || true

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
byedpictl background tunneling services

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
    *)
        echo "Invalid argument $1"
        echo "Use \"help\" command."
        exit 1
esac
