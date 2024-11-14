# byedpictl 
`byedpictl` is a tool for automating the
[byedpi](https://github.com/hufrea/byedpi) DPI bypass utility on Linux.

## Installation

> Ensure that `curl` is installed in your system.
1. Download the [latest
   archive](https://github.com/maximilionus/byedpictl/archive/refs/heads/master.zip)
   and unpack it
2. In the unpacked directory run `sudo ./install.sh`


## Usage

### Help
Get all available information about commands with:

```sh
$ byedpictl help
```

### Tunneling
Control the background tunneling with `tun <COMMAND>` command.

- Start and stop the tunneling with:
```sh
# Start
$ byedpictl tun start

# Stop
$ byedpictl tun stop
```

- Get status of background tunneling with:
```sh
$ byedpictl tun status
```


## Desync Options
To alter DPI desync (bypass) methods we can edit `BYEDPI_ARGS` in `byedpictl`
itself

```
BYEDPI_ARGS="\
--ip 127.0.0.1 --port 4080 \
< DESYNC OPTIONS HERE >"
```


## Debugging
Logs are available in `/var/log/byedpictl`.


## Possible issues
Encountering `RTNETLINK answers: File exists` message means there already
exists a network interface with the name you are tring to create, most likely
"byedpi-tun". To fix it either restart your machine or remove the existing
network interface by hand.
