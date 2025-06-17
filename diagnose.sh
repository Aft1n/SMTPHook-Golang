#!/bin/bash
set -e

echo "🔎 Running SMTPHook diagnostic..."
echo

# Colors
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

# Check binaries
echo "🧩 Checking binaries..."
BINARIES=("parser" "webhook" "webhook-server")
for bin in "${BINARIES[@]}"; do
  if [ -f "/opt/smtphook/bin/$bin" ]; then
    echo -e "✔️  /opt/smtphook/bin/$bin exists"
  else
    echo -e "${RED}❌ /opt/smtphook/bin/$bin missing${NC}"
  fi
done
echo

# Check service directories and envs
echo "📁 Checking working directories and .env files..."
for dir in "${BINARIES[@]}"; do
  path="/opt/smtphook/$dir"
  if [ -d "$path" ]; then
    echo -e "✔️  $path exists"
    if [ -f "$path/.env" ]; then
      echo "   └── .env found"
    else
      echo -e "   └── ${RED}.env missing${NC}"
    fi
  else
    echo -e "${RED}❌ $path missing${NC}"
  fi
done
echo

# Check systemd service status
echo "🧠 Checking systemd service status..."
all_services_ok=true

for service in "${BINARIES[@]}"; do
  echo
  echo "🔸 ${service}.service:"
  if systemctl status "$service.service" &>/dev/null; then
    status=$(systemctl is-active "$service.service")
    if [ "$status" = "active" ]; then
      echo -e "✔️  ${GREEN}Active${NC}"
    else
      echo -e "${RED}❌ Service exists but failed to start${NC}"
      systemctl status "$service.service" --no-pager -n 5 | sed 's/^/   /'
      all_services_ok=false
    fi
  else
    echo -e "${RED}❌ ${service}.service not found in systemd${NC}"
    all_services_ok=false
  fi
done
echo

# Check logs dir
echo "📄 Checking log directory..."
if [ ! -d "logs" ]; then
  echo -e "${RED}❌ logs/ missing. Creating now...${NC}"
  mkdir -p logs
else
  echo -e "✔️  logs exists"
fi
echo

# Check open ports
echo "📡 Checking open ports..."
ss -tuln | grep -E ':1025|:4000|:4001|:8025' || echo "⚠️  No known ports currently listening"
echo

# Check for conflicting ports in .env files
echo "🧪 Checking for PORT conflicts in .env files..."
declare -A seen_ports
conflict=false
for dir in "${BINARIES[@]}"; do
  env_file="/opt/smtphook/$dir/.env"
  if [ -f "$env_file" ]; then
    port=$(grep '^PORT=' "$env_file" | cut -d '=' -f2)
    if [ -n "$port" ]; then
      if [[ -n "${seen_ports[$port]}" ]]; then
        echo -e "${RED}❌ Port $port used in both ${seen_ports[$port]} and $dir${NC}"
        conflict=true
      else
        seen_ports[$port]=$dir
        echo "✔️  $dir uses port $port"
      fi
    fi
  fi
done
echo

# Tail logs if available
echo "🧾 Tailing logs (if present)..."
for file in logs/*.log; do
  if [ -f "$file" ]; then
    echo "📜 Last 3 lines of $file:"
    tail -n 3 "$file"
    echo
  fi
done

# Final summary
echo -e "✅ Diagnostic complete."

if [ "$all_services_ok" = false ] || [ "$conflict" = true ]; then
  echo -e "${RED}⚠️  One or more issues were detected above.${NC}"
else
  echo -e "${GREEN}🚀 All services running and healthy!${NC}"
fi
