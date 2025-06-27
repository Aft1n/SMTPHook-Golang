#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."
echo ""

# Check binaries
echo "Checking binaries..."
for bin in parser webhook webhook-server; do
  if [ -x "/opt/smtphook/bin/$bin" ]; then
    echo "/opt/smtphook/bin/$bin exists"
  else
    echo "/opt/smtphook/bin/$bin missing"
  fi
done
echo ""

# Check .env files
echo "📁 Checking working directories and .env files..."
for dir in parser webhook webhook-server; do
  if [ -d "/opt/smtphook/$dir" ]; then
    echo "/opt/smtphook/$dir exists"
    if [ -f "/opt/smtphook/$dir/.env" ]; then
      echo "   └── .env found"
    else
      echo "   └── ❌ .env missing"
    fi
  else
    echo "❌ /opt/smtphook/$dir missing"
  fi
done
echo ""

# Check Quadlet systemd units
echo "🧠 Checking Quadlet container status..."

for name in smtp webhook webhook-server parser; do
  service="container-${name}.service"
  status=$(systemctl --user is-active "$service" 2>/dev/null || echo "not found")
  if [ "$status" == "active" ]; then
    echo "$service is active"
  else
    echo "❌ $service is not active"
  fi
done
echo ""

# Check ports
echo "Checking open ports..."
ss -tuln | grep -E ':1025|:4000|:4001|:8025' || echo "⚠️  No expected ports open"
echo ""

# Check log dir
echo "📄 Checking log directory..."
if [ -d logs ]; then
  echo "logs exists"
else
  echo "❌ logs directory missing"
fi
echo ""

# Check logs
echo "🧾 Tailing logs (if present)..."
for name in parser webhook webhook-server; do
  file="logs/${name}.log"
  if [ -f "$file" ]; then
    echo "Last lines of $file:"
    tail -n 5 "$file"
  else
    echo "$file not found"
  fi
done

echo ""
echo "✅ Diagnostic complete."
