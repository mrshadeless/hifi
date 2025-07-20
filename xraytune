#!/bin/bash
set -e

LOG_FILE="/var/log/xeaytun.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🚀 Installing xray-core..."
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y iproute2 iptables curl wget unzip net-tools resolvconf

echo "🔧 Installing tun2socks..."
mkdir -p /opt/tun2socks
cd /opt/tun2socks
TUN2SOCKS_VERSION=$(curl -s https://api.github.com/repos/xjasonlyu/tun2socks/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -q "https://github.com/xjasonlyu/tun2socks/releases/download/${TUN2SOCKS_VERSION}/tun2socks-linux-amd64.zip"
unzip -o tun2socks-linux-amd64.zip
chmod +x tun2socks
sudo mv tun2socks /usr/local/bin/

echo "⚙️ Writing Xray config.json..."
sudo tee /usr/local/etc/xray/config.json >/dev/null <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "FRanCe.PiAzDAgh.cOm",
            "port": 443,
            "users": [
              {
                "id": "a5bb85e5-afc6-41f6-89b7-c282db73876b",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "frANce.pIaZdAgh.cOM",
          "alpn": ["h2"]
        },
        "wsSettings": {
          "path": "/TYeJHnpeVa7aVfoYPJnbZ9e",
          "headers": {
            "Host": "france.piazdagh.com"
          }
        }
      },
      "mux": {
        "enabled": true,
        "concurrency": 4
      }
    }
  ]
}
EOF

echo "🎛️ Writing tun2socks systemd service..."
sudo tee /etc/systemd/system/tun2socks.service >/dev/null <<EOF
[Unit]
Description=Route traffic through tun2socks
After=network.target xray.service
Requires=xray.service

[Service]
Type=simple
ExecStart=/usr/local/bin/tun2socks -device tun0 -proxy socks5://127.0.0.1:10808 -interface eth0 -udpgw-remote 127.0.0.1:7300
Restart=on-failure
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW
ExecStartPre=/sbin/ip tuntap add dev tun0 mode tun
ExecStartPre=/sbin/ip addr add 10.0.0.1/24 dev tun0
ExecStartPre=/sbin/ip link set tun0 up

[Install]
WantedBy=multi-user.target
EOF

echo "📡 Configuring IP routes through tun0..."
sudo ip tuntap add dev tun0 mode tun || true
sudo ip addr add 10.0.0.1/24 dev tun0 || true
sudo ip link set tun0 up || true
sudo ip route add default dev tun0 table 100 || true
sudo ip rule add from 10.0.0.2 lookup 100 || true

echo "▶️ Enabling and starting services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable xray
sudo systemctl enable tun2socks
sudo systemctl restart xray
sudo systemctl restart tun2socks

echo "🌐 Setting up proxy environment for current session..."
export http_proxy="socks5h://127.0.0.1:10808"
export https_proxy="socks5h://127.0.0.1:10808"

echo "🌍 Persisting proxy environment globally..."
sudo tee /etc/profile.d/proxy.sh >/dev/null <<EOF
export http_proxy="socks5h://127.0.0.1:10808"
export https_proxy="socks5h://127.0.0.1:10808"
EOF
sudo chmod +x /etc/profile.d/proxy.sh

echo "📦 Configuring apt to use proxy..."
sudo tee /etc/apt/apt.conf.d/99proxy >/dev/null <<EOF
Acquire::http::Proxy "socks5h://127.0.0.1:10808/";
Acquire::https::Proxy "socks5h://127.0.0.1:10808/";
EOF

echo "✅ Installation complete. Xray and tun2socks are running."
