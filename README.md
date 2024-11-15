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
### Random errors on execution
`RTNETLINK answers: File exists` or any other similar messages on execution
shall be ignored. The project is in very early state of development, so STDs
redirection are not yet handled correctly.


### Tunnel after suspend
Tunneling **will** break after waking your PC from suspend (sleep) state. To
restore the functionality you should run the command below:

```sh
$ byedpictl tun restart
```
