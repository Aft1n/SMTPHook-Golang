#!/bin/bash
set -e

echo "🔍 Detecting OS and package manager..."
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

echo "📦 Installing dependencies using $PM..."

case $PM in
  apt)
    sudo apt-get update
    sudo apt-get install -y golang git make podman python3-pip logrotate
    sudo pip3 install podman-compose
    ;;
  dnf)
    sudo dnf install -y golang git make podman python3-pip logrotate
    sudo pip3 install podman-compose
    ;;
  apk)
    sudo apk add go git make podman py3-pip logrotate
    sudo pip3 install podman-compose
    ;;
esac

echo "📁 Creating logs/ directory..."
mkdir -p logs

echo "🔧 Copying .env.example files..."
for dir in parser webhook webhook-server; do
  if [ ! -f "$dir/.env" ] && [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "✔️  $dir/.env created"
  fi
done

echo "🔨 Building services..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo mkdir -p /opt/smtphook/bin
sudo cp bin/* /opt/smtphook/bin

echo "🛠 Installing systemd service units..."
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo cp etc/system/systemd/smtphook.target /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🔌 Enabling and starting services..."
sudo systemctl enable smtphook.target
sudo systemctl start smtphook.target

echo "🌀 Installing logrotate config..."
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/

echo "✅ Setup complete. SMTPHook is running!"
