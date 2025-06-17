#!/bin/bash
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script with sudo or as root."
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
    apt update
    apt install -y golang git make podman pipx logrotate swaks
    ;;
  dnf)
    dnf install -y golang git make podman python3-pip pipx logrotate swaks
    ;;
  apk)
    apk add go git make podman py3-pip logrotate
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
chown "$(logname 2>/dev/null || echo $SUDO_USER)" logs || true

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
mkdir -p /opt/smtphook/bin
cp bin/* /opt/smtphook/bin

echo "📁 Preparing /opt/smtphook service directories..."
for dir in parser webhook webhook-server; do
  mkdir -p "/opt/smtphook/$dir"
  if [ -f "$dir/.env" ]; then
    cp "$dir/.env" "/opt/smtphook/$dir/.env"
    echo "✔️  /opt/smtphook/$dir/.env deployed"
  fi
done

echo "🛠 Installing systemd service units..."
SYSTEMD_SRC="etc/system/systemd"
SYSTEMD_DST="/etc/systemd/system"

SERVICE_FILES=("parser.service" "webhook.service" "webhook-server.service" "smtphook.target")

for svc in "${SERVICE_FILES[@]}"; do
  if [ -f "$SYSTEMD_SRC/$svc" ]; then
    cp "$SYSTEMD_SRC/$svc" "$SYSTEMD_DST/$svc"
    echo "✔️  Installed $svc"
  else
    echo "⚠️  $svc not found in $SYSTEMD_SRC"
  fi
done

echo "🔁 Reloading systemd daemon..."
systemctl daemon-reexec
systemctl daemon-reload

echo "🔌 Enabling and starting smtphook services..."
systemctl enable smtphook.target
systemctl enable parser.service
systemctl enable webhook.service
systemctl enable webhook-server.service
systemctl start smtphook.target

echo "🌀 Installing logrotate config..."
cp etc/logrotate.d/smtphook /etc/logrotate.d/

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

echo "✅ Setup complete. SMTPHook is running!"
echo "📤 You can now test mail input with:"
echo "    swaks --to test@example.com --server localhost:1025 < email.txt"
