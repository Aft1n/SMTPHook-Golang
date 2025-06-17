#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."
echo

echo "🧩 Checking binaries..."
for bin in parser webhook webhook-server; do
  if [ -f "/opt/smtphook/bin/$bin" ]; then
    echo "✔️  /opt/smtphook/bin/$bin exists"
  else
    echo "❌ /opt/smtphook/bin/$bin missing"
  fi
done

echo
echo "📁 Checking working directories and .env files..."
for dir in parser webhook webhook-server; do
  if [ -d "/opt/smtphook/$dir" ]; then
    echo "✔️  /opt/smtphook/$dir exists"
    if [ -f "/opt/smtphook/$dir/.env" ]; then
      echo "   └── .env found"
    else
      echo "   ❌ .env missing"
    fi
  else
    echo "❌ /opt/smtphook/$dir missing"
  fi
done

echo
echo "🧠 Checking systemd service status..."
for service in parser webhook webhook-server; do
  echo
  echo "🔸 ${service}.service:"
  if systemctl list-unit-files | grep -q "^${service}.service"; then
    if systemctl is-active --quiet "$service"; then
      systemctl status "$service" --no-pager -n 1 | sed 's/^/   /'
    else
      echo "   ❌ Service exists but failed to start"
      systemctl status "$service" --no-pager -n 3 | sed 's/^/   /'
    fi
  else
    echo "   ❌ ${service}.service not found in systemd"
  fi
done

echo
echo "📄 Checking log directory..."
if [ -d logs ]; then
  echo "✔️  logs exists"
else
  echo "❌ logs directory missing"
fi

echo
echo "📡 Checking open ports..."
ss -tuln | grep -E ':1025|:8025|:4000|:4001' || echo "❌ No expected ports open"

echo
echo "🧪 Checking for PORT conflicts in .env files..."
for dir in parser webhook webhook-server; do
  if [ -f "$dir/.env" ]; then
    echo "→ $dir/.env: $(grep PORT= "$dir/.env" || echo 'PORT not defined')"
  fi
done

echo
echo "🧾 Tailing logs (if present)..."
for service in parser webhook webhook-server; do
  logfile="logs/${service}.log"
  if [ -f "$logfile" ]; then
    echo "→ Last log lines from $logfile:"
    tail -n 3 "$logfile"
  fi
done

echo
echo "✅ Diagnostic complete."
