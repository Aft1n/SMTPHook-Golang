#!/bin/bash

set -e

# Check we're in the right folder
if [ ! -f "setup.sh" ] || [ ! -d "parser" ]; then
  echo "❌ Run this script from the root of the SMTPHook-Golang repository"
  exit 1
fi

echo "🔍 Detecting package manager..."

if command -v apt &>/dev/null; then
  PM="apt"
  INSTALL="sudo apt update && sudo apt install -y"
elif command -v dnf &>/dev/null; then
  PM="dnf"
  INSTALL="sudo dnf install -y"
elif command -v apk &>/dev/null; then
  PM="apk"
  INSTALL="sudo apk add"
else
  echo "❌ Supported package manager not found (apt, dnf, apk)"
  exit 1
fi

echo "✅ Package manager detected: $PM"

echo "📦 Installing dependencies..."
$INSTALL golang git make curl pipx swaks

echo "🧰 Installing podman and podman-compose..."
$INSTALL podman

# Ensure pipx is available
python3 -m ensurepip --upgrade || true
pipx ensurepath
pipx install podman-compose || true

echo "📁 Creating logs/ directory..."
mkdir -p logs

echo "🔧 Copying .env.example files..."
for dir in parser webhook webhook-server; do
  if [ -f "$dir/.env.example" ] && [ ! -f "$dir/.env" ]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "✔️  $dir/.env created"
  fi
done

echo "🧹 Running go mod tidy for all services..."
for dir in parser webhook webhook-server; do
  echo "→ Tidying $dir"
  (cd $dir && go mod tidy)
done

echo "🔨 Building services with Make..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo make install

echo "🛠 Installing systemd service units..."
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo cp etc/system/systemd/smtphook.target /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable smtphook.target || true
sudo systemctl start smtphook.target || true

echo "🧪 Creating sample email.txt for testing..."
cat > email.txt <<EOF
From: test@example.com
To: demo@example.com
Subject: Test Email

This is a test message body.
EOF
echo "✔️  email.txt created"

echo "✅ Setup complete!"
