#!/bin/bash
set -e

echo "📁 Verifying you are in the correct project root directory..."

EXPECTED_ITEMS=("parser" "webhook" "webhook-server" "Makefile" "etc" "setup.sh")

for item in "${EXPECTED_ITEMS[@]}"; do
  if [ ! -e "$item" ]; then
    echo "❌ Missing required item: $item"
    echo "➡️  Please run this script from the root of the SMTPHook project directory."
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
  echo "❌ Unsupported package manager. Please install dependencies manually."
  exit 1
fi

echo "📦 Installing dependencies with $PM..."
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
    echo "⚠️  Please install swaks manually on Alpine (not in default repos)."
    ;;
esac

echo "🧰 Installing podman-compose with pipx..."
pipx install --force podman-compose
export PATH="$HOME/.local/bin:$PATH"

echo "🧹 Running go mod tidy for all services..."
for dir in parser webhook webhook-server; do
  echo "→ Tidying $dir"
  (cd "$dir" && go mod tidy)
done

echo "📁 Creating logs/ directory..."
mkdir -p logs

echo "🔧 Copying .env.example files..."
for dir in parser webhook webhook-server; do
  if [ ! -f "$dir/.env" ] && [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "✔️  $dir/.env created"
  fi
done

echo "📄 Creating sample email.txt for testing..."
cat <<EOF > email.txt
Date: $(date -R)
To: test@example.com
From: void@Nexus
Subject: test $(date -R)

This is a test mailing
EOF
echo "✔️  email.txt created"

echo "🔨 Building services with Make..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo mkdir -p /opt/smtphook/bin
sudo cp bin/* /opt/smtphook/bin

echo "📁 Preparing /opt/smtphook service directories..."
for dir in parser webhook webhook-server; do
  sudo mkdir -p "/opt/smtphook/$dir"
  if [ -f "$dir/.env" ]; then
    sudo cp "$dir/.env" "/opt/smtphook/$dir/.env"
    echo "✔️  /opt/smtphook/$dir/.env deployed"
  fi
done

echo "🛠 Installing systemd service units..."
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo cp etc/system/systemd/smtphook.target /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🔌 Enabling and starting services..."
sudo systemctl enable parser.service
sudo systemctl enable webhook.service
sudo systemctl enable webhook-server.service
sudo systemctl enable smtphook.target
sudo systemctl start smtphook.target

echo "🌀 Installing logrotate config..."
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/

echo "✅ Setup complete. SMTPHook is running!"
echo "📤 Test email with:"
echo "    swaks --to test@example.com --server localhost:1025 < email.txt"
