#!/bin/bash
set -e

BASE_DIR="/opt/3x-ui-sync"
SERVICE_FILE="/etc/systemd/system/3x-ui-sync.service"
REPO_RAW="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/3x-ui-sync/main"

install_all() {
  echo "🔧 Installing 3X-UI Sync Manager..."

  apt update
  apt install -y python3 python3-venv curl nano

  mkdir -p $BASE_DIR
  cd $BASE_DIR

  python3 -m venv venv
  source venv/bin/activate

  pip install --upgrade pip
  pip install -r <(curl -fsSL $REPO_RAW/requirements.txt)

  curl -fsSL $REPO_RAW/sync_xui.py -o sync_xui.py
  curl -fsSL $REPO_RAW/config.env.example -o config.env

  chmod +x sync_xui.py

  curl -fsSL $REPO_RAW/systemd/3x-ui-sync.service -o $SERVICE_FILE

  systemctl daemon-reload
  systemctl enable 3x-ui-sync.service
  systemctl restart 3x-ui-sync.service

  echo "✅ Installed successfully"
  echo "⚠️ Edit config.env and restart service"
}

edit_config() {
  nano $BASE_DIR/config.env
  systemctl restart 3x-ui-sync.service
}

remove_all() {
  echo "🧹 Removing everything..."

  systemctl stop 3x-ui-sync.service || true
  systemctl disable 3x-ui-sync.service || true
  rm -f $SERVICE_FILE
  rm -rf $BASE_DIR

  systemctl daemon-reload
  systemctl daemon-reexec

  echo "✅ Fully removed"
}

status() {
  systemctl status 3x-ui-sync.service --no-pager
}

while true; do
  echo ""
  echo "=== 3X-UI Sync Manager ==="
  echo "1) Install"
  echo "2) Edit config"
  echo "3) Status"
  echo "4) Remove"
  echo "5) Exit"
  read -p "Select: " choice

  case $choice in
    1) install_all ;;
    2) edit_config ;;
    3) status ;;
    4) remove_all ;;
    5) exit ;;
    *) echo "Invalid option" ;;
  esac
done
