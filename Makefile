# Binaries directory
BIN_DIR := bin

# Services and their source directories
SERVICES := parser webhook webhook-server

.PHONY: all build clean install run

# Default target
all: build

# Build all services
build:
	@mkdir -p $(BIN_DIR)
	@for service in $(SERVICES); do \
		echo "🔨 Building $$service..."; \
		cd $$service && go build -o ../$(BIN_DIR)/$$service || exit 1; cd ..; \
	done
	@echo "✅ All services built successfully."

# Install to system path
install:
	@test -d $(BIN_DIR) || { echo "❌ Error: bin directory does not exist. Run 'make build' first."; exit 1; }
	@echo "📦 Installing binaries to /opt/smtphook/bin..."
	sudo mkdir -p /opt/smtphook/bin
	sudo cp $(BIN_DIR)/* /opt/smtphook/bin/
	@echo "✅ Installed to /opt/smtphook/bin"

# Remove built binaries
clean:
	@rm -rf $(BIN_DIR)
	@echo "🧹 Cleaned all built binaries."

# Run using podman-compose
run:
	@echo "🚀 Starting services with podman-compose..."
	podman-compose -f podman-compose.yml up --build
