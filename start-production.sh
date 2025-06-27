#!/bin/bash
set -e

COMMAND="$1"

if [ -z "$COMMAND" ]; then
  echo "Usage: $0 {setup|run|reset|uninstall|diagnose}"
  exit 1
fi

case "$COMMAND" in
  setup)
    ./setup-production.sh
    ;;
  run)
    ./run.sh
    ;;
  reset)
    ./reset.sh
    ;;
  uninstall)
    ./uninstall.sh
    ;;
  diagnose)
    ./diagnose.sh
    ;;
  *)
    echo "❌ Unknown command: $COMMAND"
    echo "Usage: $0 {setup|run|reset|uninstall|diagnose}"
    exit 1
    ;;
esac
