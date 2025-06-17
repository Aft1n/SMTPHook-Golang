# Binaries directory
BIN_DIR := bin

# Services and their source directories
SERVICES := parser webhook webhook-server

.PHONY: all build clean install run

all: build

build:
	@mkdir -p $(BIN_DIR)
	@for service in $(SERVICES); do \
		echo "Building $$service..."; \
		cd $$service && go build -o ../$(BIN_DIR)/$$service && cd ..; \
	done
	@echo "✅ All services built."

install:
	@echo "Installing binaries to /opt/smtphook/bin..."
	sudo mkdir -p /opt/smtphook/bin
	sudo cp $(BIN_DIR)/* /opt/smtphook/bin/
	@echo "✅ Installed."

clean:
	@rm -rf $(BIN_DIR)
	@echo "🧹 Cleaned."

run:
	@echo "Starting via podman-compose..."
	podman-compose -f podman-compose.yml up --build
