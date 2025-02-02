# byedpictl
Experimental utility for user-friendly DPI desync on Linux


## Install
1. Download the [latest
   archive](https://github.com/maximilionus/byedpictl/archive/refs/heads/master.zip)
   and unpack it.
2. In the unpacked directory run:
   ```sh
   $ sudo ./make.sh install
   ```

## Remove
1. Use the same `make.sh` script to remove the project:
   ```sh
   $ sudo ./make.sh remove
   ```

## Update
1. Be sure to uninstall the project using the same `make.sh` script that was
   used for initial installation.
2. Follow the "Install" section above.

## Usage
### General
Get all the available information about utility commands usage with:
```sh
$ byedpictl help
```

### Tunneling
Control the background tunneling.

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


## Configuration
DPI desync (bypass) parameters can be modified by altering the contents of
`/etc/byedpictl/desync.conf` file


## Debugging
Logs are available in `/var/log/byedpictl`


## Possible issues
### Random errors on execution
`RTNETLINK answers: File exists` or any other similar messages on execution
shall be ignored. The project is in a very early state of development, so
there's a lot of "garbage" output.

### Tunnel after suspend
Tunneling **will** break after waking your PC from suspend (sleep) state. To
restore the functionality you should run the command below:
```sh
$ byedpictl tun restart
```
