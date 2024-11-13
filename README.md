# byedpictl 
`byedpictl` is a convinience script for running [byedpi](https://github.com/hufrea/byedpi) and [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel) in conjuction for better protection against DPI.

## Installation
1) Though, it is installed by default on most distributions, make sure `curl` is installed
2) Download the [latest archive](https://github.com/maximilionus/byedpictl/archive/refs/heads/master.zip) and unpack it
3) In the unpacked directory run `sudo ./install.sh`

## Usage
Controll the script with `sudo ./byedpictl tun {start|stop|restart|status}`

```
start
   enabled full traffic tunneling

stop
   disable full traffic tunneling

restart
  restart the script

status
  see current status of byedpi and socks5 proxy
```
See the list of possible commands with `./bydpictl help`

## Altering bydepi arguments
To alter DPI bypasss methods we can edit `BYEDPI_ARGS` in `byedpictl` itself
```
BYEDPI_ARGS="\
--ip 127.0.0.1 --port 4080 \
--proto=udp --udp-fake=2 \
--proto=http,tls --disoob=1 \
--auto=torst --disoob=1 --tlsrec 3+s \
--auto=torst --timeout=3"
```

## Debugging
Logs are available here `/var/log/byedpictl`.

## Possible issues
Encountering `RTNETLINK answers: File exists` message means there already exists a network interface with the name you are tring to create, most likely "byedpi-tun".
To fix it either restart your machine or remove the existing network interface by hand.
