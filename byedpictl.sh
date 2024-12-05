#!/bin/bash
set -e

BYEDPI_ARGS="\
--ip 127.0.0.1 --port 4080 \
--proto=udp --oob=4+s --udp-fake=2 \
--proto=http,tls --disoob=4+s \
--auto=torst --disorder=4 --split=2 --tlsrec 1+s \
--auto=torst --timeout=3"

BIN_DIR="/usr/local/bin"
CONF_DIR="/etc/byedpi"
LOG_DIR="/var/log/byedpi"
PID_DIR="/var/run/byedpi"


cmd_help() {
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

cmd_tun() {
    case $1 in
        start)
            start_tunneling
            echo "Successfully enabled full traffic tunneling."
            ;;
        stop)
            stop_tunneling
            echo "Successfully stopped the tunneling."
            ;;
        restart)
            stop_tunneling
            start_tunneling
            echo "Tunnel successfully restarted."
            ;;
        status)
            show_tunneling_status
            ;;
        *)
            echo "Error: Invalid mode: \"$1\"."
    esac
}

prepare_dirs() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
}

start_tunneling() {
    prepare_dirs

    nohup su - byedpi -s /bin/bash -c "$BIN_DIR/ciadpi $BYEDPI_ARGS" \
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
}

stop_tunneling() {
    user_id=$(id -u byedpi)
    nic_name=$(ip route show to default | awk '$5 != "byedpi-tun" {print $5; exit}')
    gateway_addr=$(ip route show to default | awk '$5 != "byedpi-tun" {print $3; exit}')

    # Not sure if that's a good idea to let all steps be passable by default
    # as this may lead to a lot of unexpected behavior. There should be at
    # least some "is command even available" checks here.

    ip rule del uidrange $user_id-$user_id lookup 110 pref 28000 || true
    ip route del default via "$gateway_addr" dev "$nic_name" metric 50 table 110 || true
    ip route del default via 172.20.0.1 dev byedpi-tun metric 1 || true

    kill $(cat $PID_DIR/tunnel.pid) || true
    kill $(cat $PID_DIR/server.pid) || true

    rm -rf "$PID_DIR" || true
}

show_tunneling_status() {
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
