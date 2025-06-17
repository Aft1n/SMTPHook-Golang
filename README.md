# SMTPHook

SMTPHook is a modular email processing platform built in Go. It receives SMTP email, parses the content into structured JSON, and forwards it to a webhook endpoint for ingestion.

It is **Ready**, with support for:
- Systemd-managed services
- Log rotation
- Health checks
- Retry logic
- Polling for new messages
- Podman or Docker containers (optional for testing)

---

## 📁 Project Structure

```
SMTPHook-Golang-main/
├── parser/                    # Parses raw emails and sends structured JSON to webhook
│   ├── main.go
│   ├── go.mod
│   ├── Dockerfile
│   └── .env.example
├── webhook/                  # Test webhook endpoint that receives parsed email JSON
│   ├── main.go
│   ├── go.mod
│   ├── Dockerfile
│   └── .env.example
├── webhook-server/           # Production webhook receiver, saves logs and performs actions
│   ├── main.go
│   ├── go.mod
│   ├── Dockerfile
│   └── .env.example
├── mailpit/                  # Dockerfile for Mailpit (SMTP debugging server)
│   └── Dockerfile
├── etc/
│   ├── logrotate.d/
│   │   ├── logrotate-smtphook.conf
│   │   └── smtphook
│   └── system/systemd/
│       ├── parser.service
│       ├── webhook.service
│       ├── webhook-server.service
│       ├── smtphook.service
│       └── smtphook.target
├── logs/                     # Auto-created log directory
├── email.txt                 # Sample email for testing with swaks
├── sample-email.json         # Sample webhook POST body
├── podman-compose.yml        # Podman-compatible Docker Compose for all services
├── Makefile                  # Build automation
├── setup.sh                  # Full automatic setup
├── uninstall.sh              # Clean uninstaller
├── reset.sh                  # Resets everything (purge+uninstall+logs)
├── run.sh                    # Manual start script (non-systemd)
├── diagnose.sh               # Diagnostic tool
└── README.md                 # This file
```

---

## ⚡ Quick Start

```bash
git clone https://github.com/your-user/SMTPHook-Golang.git
cd SMTPHook-Golang
chmod +x setup.sh
./setup.sh
```

This script:
- Installs dependencies (Go, Podman, pipx, swaks)
- Builds and installs services
- Sets up `.env` files and log folder
- Copies systemd units
- Starts services
- Provides test samples

---

## 🧪 Testing

### 📤 Send an email
```bash
swaks --to test@example.com --server localhost:1025 < email.txt
```

### 🌐 Test webhook directly
```bash
curl -X POST http://localhost:4000/email -H "Content-Type: application/json" -d @sample-email.json
```

### 🩺 Health check
```bash
curl http://localhost:4000/health
```

---

## 🛠 Service Management (systemd)

```bash
sudo systemctl status smtphook.target
sudo journalctl -u parser.service -f
```

---

## 📦 Logrotate

Log files are rotated daily via `logrotate`:
```bash
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/
```

---

## 🧼 Maintenance Scripts

| Script         | Description                             |
|----------------|-----------------------------------------|
| `setup.sh`     | Installs and configures everything      |
| `uninstall.sh` | Removes all binaries, services, configs |
| `reset.sh`     | Full purge, uninstall, and cleanup      |
| `diagnose.sh`  | Diagnoses services, ports, logs         |

---

## 📡 Internal Flow

1. `Mailpit` listens on `1025`, receives emails.
2. `parser` checks for new messages in polling loop, parses and sends JSON to webhook.
3. `webhook` receives and logs JSON, forwards to `webhook-server`.
4. `webhook-server` writes logs, performs actions.

---

## ✅ Production Features

- ⛑ Health endpoints on all services
- ♻️ Retry logic on HTTP POST
- 🔁 Polling loop to continuously process new messages
- 🧠 Compatible with systemd targets and podman-compose
- 🧪 Full local testing support via Mailpit + swaks

---

## ⚙️ Customization

Set `WEBHOOK_URL`, `POLL_INTERVAL`, etc. inside `.env` files under each service.

---

## License

MIT
