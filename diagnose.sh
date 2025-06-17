#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."
echo ""

echo "🧩 Checking binaries..."
for binary in parser webhook webhook-server; do
  path="/opt/smtphook/bin/$binary"
  if [ -f "$path" ]; then
    echo "✔️  $path exists"
  else
    echo "❌ $path missing"
  fi
done
echo ""

echo "📁 Checking working directories and .env files..."
for service in parser webhook webhook-server; do
  dir="/opt/smtphook/$service"
  if [ -d "$dir" ]; then
    echo "✔️  $dir exists"
    if [ -f "$dir/.env" ]; then
      echo "   └── .env found"
    else
      echo "   └── ⚠️  .env missing"
    fi
  else
    echo "❌ $dir missing"
  fi
done
echo ""

echo "🧠 Checking systemd service status..."
for service in parser webhook webhook-server; do
  if systemctl list-units --all --type=service | grep -q "$service.service"; then
    echo ""
    echo "🔸 $service.service:"
    systemctl --no-pager --full status "$service.service" | head -n 10
  else
    echo ""
    echo "🔸 $service.service:"
    echo "❌ $service.service not found in systemd"
  fi
done

echo ""
echo "🔸 mailpit container:"
if podman ps --format "{{.Names}}" | grep -q "^mailpit$"; then
  echo "✔️  Mailpit container is running"
else
  echo "❌ Mailpit container is not running"
fi
echo ""

echo "📄 Checking log directory..."
if [ -d "logs" ]; then
  echo "✔️  logs exists"
else
  echo "❌ logs directory missing"
fi
echo ""

echo "📡 Checking open ports..."
ss -tuln | grep -E ':1025|:4000|:4001|:8025' || echo "⚠️  No expected ports open"
echo ""

echo "🧪 Checking for PORT conflicts in .env files..."
for svc in webhook webhook-server; do
  env_file="/opt/smtphook/$svc/.env"
  if [ -f "$env_file" ]; then
    port=$(grep -E '^PORT=' "$env_file" | cut -d= -f2)
    echo "✔️  $svc uses port $port"
  fi
done
echo ""

echo "🧾 Tailing logs (if present)..."
for svc in parser webhook webhook-server; do
  log_file="logs/${svc}.log"
  if [ -f "$log_file" ]; then
    echo "📄 Last 5 lines of $log_file:"
    tail -n 5 "$log_file"
  else
    echo "⚠️  logs/${svc}.log not found"
  fi
done

echo ""
echo "✅ Diagnostic complete."
echo "⚠️  One or more issues were detected above if marked."
