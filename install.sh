#!/usr/bin/env bash

CONFIG_URL="https://raw.githubusercontent.com/vayzur/pctl/main/config.json"
CTL_URL="https://raw.githubusercontent.com/vayzur/pctl/main/pctl"
CORE_URL="https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this installer requires root."
  exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
  echo "Error: this installer only supports Linux."
  exit 1
fi

arch="$(uname -m)"
if [ "$arch" != "x86_64" ]; then
  echo "Error: this installer only supports x86_64."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required. Install curl and run this again."
  exit 1
fi

if command -v ss >/dev/null 2>&1; then
  port_in_use() { ss -ltn "sport = :$1" 2>/dev/null | sed -n '2,$p' | grep -q .; }
elif command -v netstat >/dev/null 2>&1; then
  port_in_use() { netstat -ltn 2>/dev/null | grep -q ":$1 "; }
else
  echo "Error: ss or netstat is required."
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if ! curl -fsSL "$CORE_URL" -o "$tmpdir/psiphon-core"; then
  echo "Error: failed to download psiphon-core."
  exit 1
fi
chmod +x "$tmpdir/psiphon-core"
install -m 0755 "$tmpdir/psiphon-core" /usr/local/bin/psiphon-core || {
  echo "Error: failed to install psiphon-core."
  exit 1
}

mkdir -p /etc/psiphon || {
  echo "Error: failed to create /etc/psiphon."
  exit 1
}

if ! curl -fsSL "$CONFIG_URL" -o /etc/psiphon/config.json; then
  echo "Error: failed to install config.json."
  exit 1
fi

cat > /etc/systemd/system/psiphon.service <<'EOF'
[Unit]
Description=Psiphon Tunnel
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/psiphon-core -config /etc/psiphon/config.json -dataRootDirectory /etc/psiphon
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

if ! curl -fsSL "$CTL_URL" -o /usr/local/bin/pctl; then
  echo "Error: failed to install pctl."
  exit 1
fi
chmod +x /usr/local/bin/pctl || {
  echo "Error: failed to make pctl executable."
  exit 1
}

systemctl daemon-reload || {
  echo "Error: systemctl daemon-reload failed."
  exit 1
}

http_port="$(python3 -c "import json; d=json.load(open('/etc/psiphon/config.json')); print(d['LocalHttpProxyPort'])")"
socks_port="$(python3 -c "import json; d=json.load(open('/etc/psiphon/config.json')); print(d['LocalSocksProxyPort'])")"

http_busy=0
socks_busy=0
if port_in_use "$http_port"; then
  http_busy=1
  echo "Warning: port $http_port is already in use."
fi
if port_in_use "$socks_port"; then
  socks_busy=1
  echo "Warning: port $socks_port is already in use."
fi

if [ "$http_busy" -eq 1 ] || [ "$socks_busy" -eq 1 ]; then
  echo "Psiphon was installed, but the service was not started."
  echo "Change the ports with 'pctl http <PORT>' and 'pctl socks <PORT>' after install."
else
  systemctl enable --now psiphon || {
    echo "Error: service install succeeded, but starting psiphon failed."
    exit 1
  }
  echo "Psiphon installed and running."
fi

echo "pctl is installed at /usr/local/bin/pctl"
echo "Use 'pctl help' to see commands."
