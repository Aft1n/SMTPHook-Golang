#!/usr/bin/env bash
set -e

# Ensure script is run from project root
if [[ ! -f "setup.sh" || ! -d "parser" ]]; then
  echo "❌ Please run this script from the project root directory."
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
  echo "❌ Unsupported package manager."
  exit 1
fi
echo "✅ Package manager detected: $PM"

echo "📦 Installing dependencies..."
eval "$INSTALL golang git make curl pipx swaks"

echo "🧰 Ensuring pipx is initialized..."
pipx ensurepath || true

echo "🧰 Ensuring podman-compose is installed via pipx..."
pipx install podman-compose || true

echo "🧹 Running go mod tidy for all services..."
for svc in parser webhook webhook-server; do
  echo "→ Tidying $svc"
  (cd "$svc" && go mod tidy)
done

echo "📁 Creating logs/ directory..."
mkdir -p logs

echo "📁 Creating /opt/smtphook/* service directories..."
sudo mkdir -p /opt/smtphook/{parser,webhook,webhook-server}
echo "✅ Service folders created in /opt/smtphook/"

echo "🔧 Copying .env.example files..."
for svc in parser webhook webhook-server; do
  if [[ -f "$svc/.env.example" ]]; then
    cp -n "$svc/.env.example" "$svc/.env" && echo "✔️  $svc/.env created"
  fi
done

echo "🔨 Building services with Make..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo mkdir -p /opt/smtphook/bin
sudo cp bin/* /opt/smtphook/bin/
echo "✅ Installed to /opt/smtphook/bin"

echo "🛠 Installing systemd service units..."
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo cp etc/system/systemd/smtphook.target /etc/systemd/system/

echo "🔌 Enabling and starting services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable smtphook.target
sudo systemctl start smtphook.target || echo "⚠️  Some services failed to start. Run 'journalctl -xe' for details."

echo "🧪 Creating sample email.txt for testing..."
cat > email.txt <<EOF
From: test@example.com
To: receiver@example.com
Subject: Test Email

This is a test email sent using swaks.
EOF
echo "✔️  email.txt created"

echo "✅ Setup complete!"
