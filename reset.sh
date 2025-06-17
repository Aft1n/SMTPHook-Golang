#!/bin/bash
set -e

echo "🧨 Stopping and removing all SMTPHook-related containers and images..."

SERVICES=("parser" "webhook" "webhook-server" "smtp")

# Stop and remove containers
for service in "${SERVICES[@]}"; do
  echo "⛔️ Stopping $service container (if running)..."
  podman stop "$service" 2>/dev/null || true
  podman rm "$service" 2>/dev/null || true

  echo "🧹 Removing image for $service (if present)..."
  podman rmi "localhost/smtphook-golang_$service" 2>/dev/null || true

  echo "🧼 Cleaning up Quadlet container unit..."
  CONTAINER_UNIT="$HOME/.config/containers/systemd/container-${service}.container"
  if [ -f "$CONTAINER_UNIT" ]; then
    systemctl --user disable --now "container-${service}.service" 2>/dev/null || true
    rm -f "$CONTAINER_UNIT"
    echo "✔️ Removed $CONTAINER_UNIT"
  fi
done

echo "📂 Cleaning container systemd folder..."
rm -rf "$HOME/.config/containers/systemd"

echo "🧽 Removing /opt/smtphook installation..."
sudo rm -rf /opt/smtphook

echo "🧹 Cleaning up build output..."
rm -rf bin logs email.txt

echo "📄 Reset complete. All containers and services have been removed."
echo "🔁 You can now re-run ./setup.sh to start fresh."
