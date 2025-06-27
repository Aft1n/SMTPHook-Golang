#!/bin/bash
set -e

# Prevent running as root
if [ "$EUID" -eq 0 ]; then
  echo "Do NOT run this script as root or with sudo."
  echo "Please run: ./setup-production.sh"
  exit 1
fi

echo "Verifying you are in the correct project root directory..."

EXPECTED_ITEMS=("parser" "Makefile" "etc" "setup-production.sh")

for item in "${EXPECTED_ITEMS[@]}"; do
  if [ ! -e "$item" ]; then
    echo "Missing required item: $item"
    echo "Please run this script from the root of the SMTPHook project directory."
    exit 1
  fi
done

echo "Detecting package manager..."
if command -v apt-get &>/dev/null; then
  PM="apt"
elif command -v dnf &>/dev/null; then
  PM="dnf"
elif command -v apk &>/dev/null; then
  PM="apk"
else
  echo "Unsupported package manager. Please install dependencies manually."
  exit 1
fi

echo "Installing dependencies with $PM..."

case $PM in
  apt)
    sudo apt update
    sudo apt install -y golang git make podman logrotate swaks curl wget python3-pip pipx
    ;;
  dnf)
    sudo dnf install -y golang git make podman logrotate swaks curl wget python3-pip pipx
    ;;
  apk)
    sudo apk add go git make podman py3-pip logrotate swaks curl wget pipx
    ;;
esac

# Ensure pipx is usable and path is loaded
pipx ensurepath
if ! grep -q '.local/bin' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.local/bin:$PATH"

# Install podman-compose if missing
echo "Ensuring podman-compose is installed..."
if ! command -v podman-compose &>/dev/null; then
  pipx install podman-compose
else
  echo "podman-compose is already installed."
fi

# Go version check and optional install
REQUIRED_GO_VERSION="1.21"
GO_TARBALL="go1.21.10.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/$GO_TARBALL"

if command -v go &>/dev/null; then
  CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
  if dpkg --compare-versions "$CURRENT_GO_VERSION" lt "$REQUIRED_GO_VERSION"; then
    echo "Your Go version is $CURRENT_GO_VERSION, but $REQUIRED_GO_VERSION or later is required."
    read -p "Do you want to uninstall your old Go version and install $REQUIRED_GO_VERSION? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      sudo apt remove -y golang-go || true
      sudo rm -rf /usr/local/go
      curl -LO "$GO_URL"
      sudo tar -C /usr/local -xzf "$GO_TARBALL"
      rm "$GO_TARBALL"
    else
      echo "Setup aborted: Go version too old."
      exit 1
    fi
  else
    echo "Go version ($CURRENT_GO_VERSION) is compatible."
  fi
else
  echo "Go not found. Installing Go $REQUIRED_GO_VERSION..."
  curl -LO "$GO_URL"
  sudo tar -C /usr/local -xzf "$GO_TARBALL"
  rm "$GO_TARBALL"
fi

# Add Go to PATH permanently and immediately
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi
export PATH=$PATH:/usr/local/go/bin

# Final check
echo "Go version: $(go version)"
echo "podman-compose version: $(podman-compose --version)"

echo "Running make build-prod..."
make build-prod

echo "Production setup complete. You can now run:"
echo "  podman-compose -f podman-compose-prod.yml up"
