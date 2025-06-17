#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."

SERVICES=("parser" "webhook" "webhook-server")
BIN_DIR="/opt/smtphook/bin"
WORKDIR_BASE="/opt/smtphook"
LOG_DIR="logs"

echo ""
echo "🧩 Checking binaries..."
for service in "${SERVICES[@]}"; do
  if [ -x "$BIN_DIR/$service" ]; then
    echo "✔️  $BIN_DIR/$service exists"
  else
    echo "❌ Missing or not executable: $BIN_DIR/$service"
  fi
done

echo ""
echo "📁 Checking working directories and .env files..."
for service in "${SERVICES[@]}"; do
  if [ -d "$WORKDIR_BASE/$service" ]; then
    echo "✔️  $WORKDIR_BASE/$service exists"
    if [ -f "$WORKDIR_BASE/$service/.env" ]; then
      echo "   └── .env found"
    else
      echo "   └── ❌ Missing .env file"
    fi
  else
    echo "❌ $WORKDIR_BASE/$service missing"
  fi
done

echo ""
echo "🧠 Checking systemd service status..."
for service in "${SERVICES[@]}"; do
  echo ""
  echo "🔸 $service.service:"
  systemctl --no-pager --quiet is-active "$service.service" && echo "✔️  Active" || echo "❌ Inactive or failed"
  systemctl status "$service.service" --no-pager | grep -E "Active|ExecStart|WorkingDirectory|EnvironmentFile" || true
done

echo ""
echo "📄 Checking log directory..."
if [ -d "$LOG_DIR" ]; then
  echo "✔️  $LOG_DIR/ exists"
else
  echo "❌ Missing $LOG_DIR/ — expected for log output"
fi

echo ""
echo "📡 Checking open ports..."
ss -tuln | grep -E ":1025|:8025|:4000" || echo "⚠️  Expected service ports not open"

echo ""
echo "🧾 Tailing logs (if present)..."
for log_file in "$LOG_DIR"/*.log; do
  if [ -f "$log_file" ]; then
    echo ""
    echo "🔹 $log_file (last 5 lines):"
    tail -n 5 "$log_file"
  fi
done

echo ""
echo "✅ Diagnostic complete."
