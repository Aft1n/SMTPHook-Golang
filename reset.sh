#!/bin/bash
set -e

echo "🧹 Stopping Quadlet containers..."

for service in container-parser container-webhook container-webhook-server container-smtp; do
  systemctl --user stop "$service.container" || true
  systemctl --user disable "$service.container" || true
done

echo "🧹 Removing Quadlet files..."
rm -f ~/.config/containers/systemd/container-*.container

echo "🗑 Removing containers..."
for name in smtphook-parser smtphook-webhook smtphook-webhook-server axllent/mailpit; do
  podman rm -f "$(podman ps -aq --filter ancestor="$name")" || true
done

echo "🧼 Cleanup complete!"
