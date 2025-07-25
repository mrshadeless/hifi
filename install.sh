#!/bin/bash

set -e

LOG_FILE="/var/log/hiddify-proxy-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🚀 Installing xray-core..."
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

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
            "address": "fr.nevisatech.net",
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
          "serverName": "fr.nevisatech.net",
          "alpn": ["h2"]
        },
        "wsSettings": {
          "path": "/TYeJHnpeVa7aVfoYPJnbZ9e",
          "headers": {
            "Host": "fr.nevisatech.net"
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

echo "▶️ Enabling and starting xray..."
sudo systemctl enable xray
sudo systemctl restart xray

echo "🌐 Setting up proxy environment for current session..."
export http_proxy="socks5h://127.0.0.1:10808"
export https_proxy="socks5h://127.0.0.1:10808"

echo "📦 Configuring apt to use proxy..."
sudo tee /etc/apt/apt.conf.d/99proxy >/dev/null <<EOF
Acquire::http::Proxy "socks5h://127.0.0.1:10808/";
Acquire::https::Proxy "socks5h://127.0.0.1:10808/";
EOF

echo "✅ Setup complete!"
echo "🔁 Please reboot or re-login to apply global proxy settings."
curl --proxy socks5h://127.0.0.1:10808 https://ipinfo.io
