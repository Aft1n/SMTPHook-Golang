#!/bin/bash
set -e

echo "🔎 Running SMTPHook production diagnostic..."
echo ""

# Check parser binary only
echo "Checking parser binary..."
if [ -x "/opt/smtphook/bin/parser" ]; then
  echo "/opt/smtphook/bin/parser exists"
else
  echo "/opt/smtphook/bin/parser missing"
fi
