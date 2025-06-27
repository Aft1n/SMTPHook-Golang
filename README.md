# SMTPHook

## ☕ Support

If you find this project useful, consider buying me a coffee:

[![Donate](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow)](https://coff.ee/voidwatch)


# SMTPHook

SMTPHook is a modular, self-hosted email processing pipeline written in Go. It listens for SMTP messages (or parses local mail files), extracts metadata and content, and sends structured JSON to an HTTP webhook.

This README reflects the **production setup**, focused entirely on the `parser` service. Development/testing components are excluded.

---

## Features

- Written in Go (1.21+)
- Production-only setup with a single service (`parser`)
- Podman + Quadlet support
- .env-based configuration
- Converts email input to JSON webhook calls
- One-command setup and reset scripts
- Compatible with PagerDuty, Opsgenie, Prometheus Alertmanager, and more

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-org/SMTPHook-Golang.git
cd SMTPHook-Golang
```

### 2. Run the production setup

This installs required tools, validates Go version, and builds the `parser` binary.

```bash
chmod +x setup-production.sh start-production.sh run-prod.sh uninstall-prod.sh reset-prod.sh diagnose-prod.sh
./start-production.sh setup
cp parser/.env.production.example parser/.env
```
Edit your parser env with your config, then choose option A or B.
NOTE: You might need to start a new shell to load the environment variables.
Try it out with Option A perhaps
```
podman-compose -f podman-compose-prod.yml up --build -d

```

---

## Info

Use `start-production.sh` to manage all production operations:

```bash
./start-production.sh setup        # Runs setup-production.sh
./start-production.sh run          # Starts the parser container
./start-production.sh diagnose     # Checks installed binary
./start-production.sh reset        # Stops container and clears logs
./start-production.sh uninstall    # Removes systemd unit
```

---

## Environment Configuration

Copy and edit the production `.env`:

```bash
cp parser/.env.production.example parser/.env
```

Example:

```env
POLL_INTERVAL=5
WEBHOOK_URL=https://your-api.local/email
MAIL_DIR=/mail/inbox
```

---

## You can run the Parser in different ways

### Option A: Podman Compose (production only)

```bash
podman-compose -f podman-compose-prod.yml up --build -d
```

### Option B: Podman + systemd (Quadlet)

```bash
mkdir -p ~/.config/containers/systemd
cp etc/quadlet/container-parser-prod.container ~/.config/containers/systemd/
systemctl --user daemon-reload
systemctl --user enable container-parser-prod.container
systemctl --user start container-parser-prod.container
```

---

## Webhook JSON Format

Emails are parsed and sent to `WEBHOOK_URL` like this:

```json
{
  "from": "alerts@example.com",
  "to": "team@example.com",
  "subject": "Disk usage critical",
  "text": "90% used on server01"
}
```

---

## Folder Structure (Production-Focused)

```
SMTPHook-Golang/
├── Makefile
├── README.md
├── sample-email.json
├── parser/
│   ├── .env.example
│   ├── .env.production.example
│   ├── Dockerfile
│   ├── go.mod
│   └── main.go
├── etc/
│   └── quadlet/
│       └── container-parser-prod.container
├── podman-compose-prod.yml
├── setup-production.sh
├── run-prod.sh
├── reset-prod.sh
├── uninstall-prod.sh
├── diagnose-prod.sh
├── start-production.sh
```

---

## Integration Tips

- The `parser` can send alerts to any HTTP endpoint that accepts JSON.
- Examples:
  - PagerDuty Events v2
  - Opsgenie Alert API
  - Prometheus Alertmanager
  - Your own internal system

You may write a simple adapter service if your API expects a different schema.

---

## License

MIT