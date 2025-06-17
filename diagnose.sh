#!/bin/bash
set -e

echo "🔎 Running SMTPHook container diagnostic..."

REQUIRED_CONTAINERS=("smtp" "webhook" "webhook-server" "parser")
REQUIRED_PORTS=("1025" "8025" "4000" "5000")

echo
echo "📦 Verifying required containers are running..."
for container in "${REQUIRED_CONTAINERS[@]}"; do
  if podman ps --format "{{.Names}}" | grep -q "^${container}$"; then
    echo "✔️  $container is running"
  else
    echo "❌ $container is NOT running"
  fi
done

echo
echo "📁 Checking service directories and .env files..."
for dir in parser webhook webhook-server; do
  if [ -d "$dir" ]; then
    echo "✔️  $dir exists"
    if [ -f "$dir/.env" ]; then
      echo "   └── .env found"
    else
      echo "   ❌ .env missing in $dir"
    fi
  else
    echo "❌ $dir directory missing"
  fi
done

echo
echo "📄 Checking logs/ directory..."
if [ -d logs ]; then
  echo "✔️  logs exists"
else
  echo "❌ logs directory not found"
fi

echo
echo "📡 Checking open ports..."
ss -tuln | grep -E ':1025|:8025|:4000|:5000' || echo "❌ No expected ports are open"

echo
echo "📑 Checking port assignments in .env files..."
check_port() {
  file="$1/.env"
  expected="$2"
  if [ -f "$file" ]; then
    port=$(grep -E '^PORT=' "$file" | cut -d= -f2)
    if [ "$port" == "$expected" ]; then
      echo "✔️  $1 uses expected port $expected"
    else
      echo "⚠️  $1 has unexpected port $port (expected $expected)"
    fi
  else
    echo "⚠️  $file not found"
  fi
}

check_port webhook 4000
check_port webhook-server 5000

echo
echo "🧾 Tailing container logs (if present)..."
for container in "${REQUIRED_CONTAINERS[@]}"; do
  echo "🔹 Logs for $container:"
  if podman ps -a --format "{{.Names}}" | grep -q "^$container$"; then
    podman logs --tail 10 "$container" || echo "⚠️  Failed to read logs for $container"
  else
    echo "⚠️  Container $container not found"
  fi
  echo
done

echo "✅ Diagnostic complete."
