#!/bin/bash
set -e

PURGE_MODE=false

if [[ "$1" == "--purge" ]]; then
  PURGE_MODE=true
fi

echo "🛑 Stopping running services (if any)..."
sudo systemctl stop smtphook.target 2>/dev/null || true
sudo systemctl stop parser.service 2>/dev/null || true
sudo systemctl stop webhook.service 2>/dev/null || true
sudo systemctl stop webhook-server.service 2>/dev/null || true

echo "🧹 Cleaning build artifacts..."
rm -rf bin/
for dir in parser webhook webhook-server; do
  rm -f "$dir/.env"
  rm -f "$dir"/"$dir"       # any accidentally generated binary
done

echo "📁 Cleaning logs/..."
rm -rf logs/

if $PURGE_MODE; then
  echo "🔥 PURGE mode: Removing installed system files..."

  echo "🗑 Disabling and removing systemd unit files..."
  sudo systemctl disable smtphook.target parser.service webhook.service webhook-server.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/parser.service
  sudo rm -f /etc/systemd/system/webhook.service
  sudo rm -f /etc/systemd/system/webhook-server.service
  sudo rm -f /etc/systemd/system/smtphook.target
  sudo systemctl daemon-reload

  echo "🗑 Removing installed binaries and service folders..."
  sudo rm -rf /opt/smtphook/bin
  sudo rm -rf /opt/smtphook/parser
  sudo rm -rf /opt/smtphook/webhook
  sudo rm -rf /opt/smtphook/webhook-server

  echo "🧻 Removing logrotate config..."
  sudo rm -f /etc/logrotate.d/smtphook
fi

echo "✅ Reset complete."
if $PURGE_MODE; then
  echo "📦 All persistent files have been purged."
else
  echo "🔁 Project is clean. You can now rerun ./setup.sh."
fi
