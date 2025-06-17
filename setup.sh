#!/bin/bash
set -e

echo "📁 Verifying you are in the correct project root directory..."
REQUIRED=("parser" "webhook" "webhook-server" "Makefile" "etc" "setup.sh")

for item in "${REQUIRED[@]}"; do
  if [ ! -e "$item" ]; then
    echo "❌ Missing: $item"
    echo "➡️  Please run this script from the root of the SMTPHook project."
    exit 1
  fi
done

echo "🔍 Detecting package manager..."
if command -v apt-get &>/dev/null; then
  PM="apt"
elif command -v dnf &>/dev/null; then
  PM="dnf"
elif command -v apk &>/dev/null; then
  PM="apk"
else
  echo "❌ Unsupported package manager."
  exit 1
fi

echo "📦 Installing dependencies via $PM..."
case $PM in
  apt)
    sudo apt update
    sudo apt install -y golang git make podman pipx logrotate swaks
    ;;
  dnf)
    sudo dnf install -y golang git make podman python3-pip pipx logrotate swaks
    ;;
  apk)
    sudo apk add go git make podman py3-pip logrotate
    python3 -m ensurepip
    pip3 install pipx
    echo "⚠️  swaks must be installed manually on Alpine."
    ;;
esac

echo "🧰 Installing podman-compose via pipx..."
pipx install --force podman-compose
export PATH="$HOME/.local/bin:$PATH"

echo "🧹 Running go mod tidy..."
for dir in parser webhook webhook-server; do
  echo "→ Tidying $dir"
  (cd "$dir" && go mod tidy)
done

echo "📁 Creating logs/ directory..."
mkdir -p logs
sudo chown "$(whoami)" logs 2>/dev/null || true

echo "🔧 Copying .env.example files if needed..."
for dir in parser webhook webhook-server; do
  if [ ! -f "$dir/.env" ] && [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "✔️  $dir/.env created"
  fi
done

echo "🔨 Building binaries..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo mkdir -p /opt/smtphook/bin
sudo cp bin/* /opt/smtphook/bin

echo "📁 Deploying .env to /opt/smtphook..."
for dir in parser webhook webhook-server; do
  sudo mkdir -p "/opt/smtphook/$dir"
  if [ -f "$dir/.env" ]; then
    sudo cp "$dir/.env" "/opt/smtphook/$dir/.env"
  fi
done

echo "🛠 Installing systemd services..."
SERVICES_DIR="etc/system/systemd"
for service in parser.service webhook.service webhook-server.service smtphook.target; do
  if [ -f "$SERVICES_DIR/$service" ]; then
    sudo cp "$SERVICES_DIR/$service" /etc/systemd/system/
  fi
done

echo "🔁 Reloading systemd..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🔌 Enabling and starting all services..."
sudo systemctl enable smtphook.target
sudo systemctl start smtphook.target

echo "🌀 Installing logrotate config..."
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/

echo "📄 Creating test email (email.txt)..."
cat <<EOF > email.txt
Date: $(date -R)
To: test@example.com
From: voidwatch@Whateversaurus
Subject: test $(date -R)
Message-Id: <$(date +%s)@Whateversaurus>
X-Mailer: swaks

This is a test mailing
EOF

echo "✅ Setup complete!"
echo "📤 Test SMTP input with:"
echo "    swaks --to test@example.com --server localhost:1025 < email.txt"
