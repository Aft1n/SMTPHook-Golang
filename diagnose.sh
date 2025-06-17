#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."
echo

# Paths
BIN_PATH="/opt/smtphook/bin"
ENV_PATH="/opt/smtphook"
LOG_DIR="logs"
PORTS=()

# Services to check
SERVICES=("parser" "webhook" "webhook-server")

echo "🧩 Checking binaries..."
for service in "${SERVICES[@]}"; do
  if [ -x "$BIN_PATH/$service" ]; then
    echo "✔️  $BIN_PATH/$service exists"
  else
    echo "❌ $BIN_PATH/$service missing or not executable"
  fi
done
echo

echo "📁 Checking working directories and .env files..."
for service in "${SERVICES[@]}"; do
  if [ -d "$ENV_PATH/$service" ]; then
    echo -n "✔️  $ENV_PATH/$service exists"
    if [ -f "$ENV_PATH/$service/.env" ]; then
      echo -e "\n   └── .env found"
      port=$(grep -E '^PORT=' "$ENV_PATH/$service/.env" | cut -d '=' -f2)
      if [[ -n "$port" ]]; then
        PORTS+=("$port:$service")
      fi
    else
      echo -e "\n   └── ❌ .env missing"
    fi
  else
    echo "❌ $ENV_PATH/$service missing"
  fi
done
echo

echo "🧠 Checking systemd service status..."
for service in "${SERVICES[@]}"; do
  echo
  echo "🔸 $service.service:"
  if systemctl list-units --type=service --all | grep -q "$service.service"; then
    systemctl --no-pager --no-legend status "$service.service" || echo "   ❌ Service exists but failed to start"
  else
    echo "❌ $service.service not found in systemd"
  fi
done
echo

echo "📄 Checking log directory..."
if [ -d "$LOG_DIR" ]; then
  echo "✔️  $LOG_DIR exists"
else
  echo "❌ $LOG_DIR missing"
fi
echo

echo "📡 Checking open ports..."
# Try ss, fallback to netstat
if command -v ss &>/dev/null; then
  NET_CMD="ss -tuln"
else
  NET_CMD="netstat -tuln"
fi
eval "$NET_CMD" | grep -E ':1025|:4000|:4001|:8025' || echo "No expected ports found open"

echo

# Detect port conflicts
echo "🧪 Checking for PORT conflicts in .env files..."
declare -A PORT_MAP
for item in "${PORTS[@]}"; do
  port="${item%%:*}"
  service="${item##*:}"
  if [[ -n "${PORT_MAP[$port]}" ]]; then
    echo "⚠️  Port conflict detected: $port used by both ${PORT_MAP[$port]} and $service"
  else
    PORT_MAP[$port]=$service
  fi
done

echo
echo "🧾 Tailing logs (if present)..."
for service in "${SERVICES[@]}"; do
  logfile="logs/${service}.log"
  if [ -f "$logfile" ]; then
    echo "→ Last 3 lines of $logfile:"
    tail -n 3 "$logfile"
  fi
done

echo
echo "✅ Diagnostic complete."
