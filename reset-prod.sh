#!/bin/bash
set -e

echo "🔁 Resetting SMTPHook (production)..."

CONTAINERS=("parser")

echo "Stopping and removing containers..."
for cname in "${CONTAINERS[@]}"; do
  if podman container exists "$cname"; then
    echo "Stopping $cname..."
    podman stop "$cname"
    podman rm "$cname"
  else
    echo "$cname not running"
  fi
done

echo "Clearing logs..."
rm -rf logs/*
echo "✅ Done"
