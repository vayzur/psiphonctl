# pctl

`pctl` is a Linux-only installer and CLI for Psiphon Tunnel Core.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/vayzur/pctl/main/install.sh | bash
```

The installer requires root. Run it from a root shell or prefix the command with `sudo`.

The installer:

- downloads the x86_64 binary from Psiphon's binary host
- installs the default config to `/etc/psiphon/config.json`
- uses `/etc/psiphon` as the persistent data directory
- installs the binary as `/usr/local/bin/psiphon-core`
- installs `pctl` to `/usr/local/bin/pctl`
- creates `/etc/systemd/system/psiphon.service`
- starts the service when ports `8081` and `1081` are free

If either port is already in use, the installer finishes but leaves the service stopped. Change the ports after install with:

```bash
pctl http <PORT>
pctl socks <PORT>
pctl restart
```

## Requirements

- Linux
- `x86_64`
- `curl`
- `python3`
- `ss` or `netstat`

Commands that change the service or config require root.

## Configuration

The active config lives at:

```text
/etc/psiphon/config.json
```

Default values:

- Egress region: `US`
- HTTP proxy port: `8081`
- SOCKS proxy port: `1081`

## Commands

### Service control

```bash
pctl start
pctl stop
pctl restart
pctl status
pctl logs
```

- `start`, `stop`, `restart` require root.
- `restart` restarts psiphon directly when it is already running. If psiphon is stopped, it checks that the configured ports are free before starting.
- `status` shows service state, region, ports, and uptime.
- `logs` follows the `psiphon` journal.

### Ports and region

```bash
pctl ports
pctl country list
pctl country US
pctl http 8082
pctl socks 1082
```

- `country list` prints the supported egress regions.
- `country <CODE>` validates the code before writing it to the config.
- `http <PORT>` and `socks <PORT>` accept values from `1024` to `65535`.

Supported country codes:

`AT`, `AU`, `BE`, `CA`, `CH`, `CZ`, `DE`, `DK`, `ES`, `FI`, `FR`, `GB`, `ID`, `IE`, `IN`, `IT`, `JP`, `LT`, `MX`, `NL`, `NO`, `PL`, `RO`, `RS`, `SE`, `SG`, `US`

### Config and maintenance

```bash
pctl config show
pctl update
pctl uninstall
pctl help
```

- `config show` pretty-prints the active config.
- `update` downloads the newest `psiphon-core` binary, then reinstalls it as `/usr/local/bin/psiphon-core` and restarts the service if it was running.
- `uninstall` removes the service, config, and installed binaries.
