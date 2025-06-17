#!/bin/bash
set -e

# Ensure we're in the project root
if [ ! -f setup.sh ] || [ ! -d parser ]; then
  echo "❌ Please run this script from the project root (where setup.sh is located)."
  exit 1
fi

echo "🔍 Detecting package manager..."
if command -v apt &>/dev/null; then
  PM="apt"
elif command -v dnf &>/dev/null; then
  PM="dnf"
elif command -v apk &>/dev/null; then
  PM="apk"
else
  echo "❌ Unsupported package manager. Install dependencies manually."
  exit 1
fi

echo "✅ Package manager detected: $PM"
echo "📦 Installing dependencies..."

if [[ "$PM" == "apt" ]]; then
  sudo apt update
  sudo apt install -y golang git make curl pipx swaks
elif [[ "$PM" == "dnf" ]]; then
  sudo dnf install -y golang git make curl pipx swaks
elif [[ "$PM" == "apk" ]]; then
  sudo apk add go git make curl py3-pip swaks
fi

echo "🧰 Ensuring pipx is initialized..."
pipx ensurepath || true
export PATH="$HOME/.local/bin:$PATH"

echo "🧰 Ensuring podman-compose is installed via pipx..."
pipx install podman-compose || true

echo "🧹 Running go mod tidy for all services..."
for dir in parser webhook webhook-server; do
  echo "→ Tidying $dir"
  (cd "$dir" && go mod tidy)
done

echo "📁 Creating logs/ directory..."
mkdir -p logs

echo "🔧 Copying .env.example files..."
for dir in parser webhook webhook-server; do
  if [ -f "$dir/.env.example" ]; then
    cp -n "$dir/.env.example" "$dir/.env" && echo "✔️  $dir/.env created"
  fi
done

echo "🔨 Building services with Make..."
make

echo "📦 Installing binaries to /opt/smtphook/bin..."
sudo make install

echo "🛠 Installing systemd service units..."
sudo cp -f etc/system/systemd/*.service /etc/systemd/system/
sudo cp -f etc/system/systemd/smtphook.target /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🔌 Enabling and starting services..."
sudo systemctl enable smtphook.target
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
