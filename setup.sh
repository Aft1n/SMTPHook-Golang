#!/bin/bash
set -e

# 🚫 Prevent running as root
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run this script as root or with sudo."
  echo "➡️  Please run: ./setup.sh"
  exit 1
fi

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
    sudo apt install -y golang git make podman pipx logrotate swaks curl wget
    ;;
  dnf)
    sudo dnf install -y golang git make podman python3-pip pipx logrotate swaks curl wget
    ;;
  apk)
    sudo apk add go git make podman py3-pip logrotate curl wget
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

echo "📬 Building and launching containers with Podman Compose..."
podman-compose -f podman-compose.yml up -d --build

echo "📁 Creating logs/ directory (again to ensure it exists)..."
mkdir -p logs

echo "🧪 Creating email.txt for swaks testing..."
cat <<EOF > email.txt
Date: $(date -R)
To: test@example.com
From: voidwatch@Whateversaurus
Subject: test $(date -R)
Message-Id: <$(date +%s)@Whateversaurus>
X-Mailer: swaks

This is a test mailing
EOF
echo "✔️  email.txt created"

echo "✅ Setup complete. SMTPHook containers are running!"
echo "📤 You can now test mail input with:"
echo "    swaks --to test@example.com --server localhost:1025 < email.txt"
