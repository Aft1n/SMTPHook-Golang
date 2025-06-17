#!/bin/bash
set -e

echo "🧨 Resetting SMTPHook environment..."

CONTAINERS=("smtp" "webhook" "webhook-server" "parser")

echo "🧹 Stopping and removing containers..."
for cname in "${CONTAINERS[@]}"; do
  if podman container exists "$cname"; then
    echo "🛑 Removing $cname..."
    podman rm -f "$cname"
  fi
done

echo "🧼 Removing old images..."
for img in "${CONTAINERS[@]}"; do
  if podman image exists "localhost/smtphook-golang_$img"; then
    podman rmi -f "localhost/smtphook-golang_$img"
  fi
done

echo "🗑 Cleaning logs and test files..."
rm -f logs/*.log || true
rm -f email.txt || true

echo "♻️  Reset complete. You can now rerun ./setup.sh"
