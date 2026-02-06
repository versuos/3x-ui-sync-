#!/bin/bash
set -e

BASE_DIR="/opt/3x-ui-sync"
SERVICE_FILE="/etc/systemd/system/3x-ui-sync.service"
REPO_RAW="https://raw.githubusercontent.com/versuos/3x-ui-sync/main"

echo ""
echo "=== 3X-UI Sync Manager ==="
echo "1) Install"
echo "2) Edit config"
echo "3) Status"
echo "4) Remove"
echo "5) Exit"
echo ""
read -p "Select option [1-5]: " CHOICE

install_all() {
  echo "🔧 Installing system dependencies..."
  apt update
  apt install -y python3 python3-venv curl nano

  echo "📁 Creating project directory..."
  mkdir -p $BASE_DIR
  cd $BASE_DIR

  echo "🐍 Creating Python virtualenv..."
  python3 -m venv venv
  source venv/bin/activate

  echo "📦 Installing Python packages (inside venv)..."
  pip install --upgrade pip
  pip install requests schedule

  echo "⬇️ Downloading project files..."
  curl -fsSL $REPO_RAW/sync_xui.py -o sync_xui.py
  curl -fsSL $REPO_RAW/config.env.example -o config.env

  chmod +x sync_xui.py

  echo "📝 Configuration"
  read -p "3X-UI Panel URL (example: http://127.0.0.1:54321): " XUI_URL
  read -p "3X-UI API Token: " XUI_TOKEN
  read -p "Telegram Bot Token (leave empty to disable): " TG_TOKEN
  read -p "Telegram Chat ID (leave empty to disable): " TG_CHAT_ID
  read -p "Sync interval in minutes [default 10]: " INTERVAL
  INTERVAL=${INTERVAL:-10}

  cat > config.env <<EOF
XUI_URL=$XUI_URL
XUI_TOKEN=$XUI_TOKEN
TG_TOKEN=$TG_TOKEN
TG_CHAT_ID=$TG_CHAT_ID
SYNC_INTERVAL=$INTERVAL
EOF

  echo "⚙️ Installing systemd service..."
  cat > $SERVICE_FILE <<EOF
[Unit]
Description=3X-UI User Sync Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$BASE_DIR
EnvironmentFile=$BASE_DIR/config.env
ExecStart=$BASE_DIR/venv/bin/python $BASE_DIR/sync_xui.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable 3x-ui-sync.service
  systemctl restart 3x-ui-sync.service

  echo ""
  echo "✅ Installation completed successfully"
  echo "Check status with: systemctl status 3x-ui-sync.service"
}

edit_config() {
  nano $BASE_DIR/config.env
  systemctl restart 3x-ui-sync.service
}

status_service() {
  systemctl status 3x-ui-sync.service --no-pager
}

remove_all() {
  echo "🧹 Removing 3X-UI Sync Manager..."

  systemctl stop 3x-ui-sync.service || true
  systemctl disable 3x-ui-sync.service || true
  rm -f $SERVICE_FILE
  rm -rf $BASE_DIR

  systemctl daemon-reload
  systemctl daemon-reexec

  echo "✅ Fully removed"
}

case $CHOICE in
  1) install_all ;;
  2) edit_config ;;
  3) status_service ;;
  4) remove_all ;;
  5) exit ;;
  *) echo "❌ Invalid option" ;;
esac
