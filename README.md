# SMTPHook

**SMTPHook** is a modular email processing platform written in Go. It receives SMTP email, parses the content into structured JSON, and sends it to your specified HTTP API endpoint — such as a PagerDuty or Opsgenie pager API.

---

## ✅ Features

- Containerized with Podman + Quadlet
- Polling loop for new messages
- Retry logic for failed webhook delivery
- Health endpoints
- Optional Mailpit test SMTP server
- One-command install & reset scripts

---

## 🚀 Getting Started

### 1. Clone and install

```bash
git clone git@github.com:voidwatch/SMTPHook-Golang.git
cd SMTPHook-Golang
chmod +x setup.sh
./setup.sh
```

### 2. Configure `.env` for `parser`

Edit `parser/.env`:

```env
POLL_INTERVAL=5
WEBHOOK_URL=http://your-api.local/pager-endpoint
```

---

## ✉️ Sending Email

Use [swaks](https://github.com/JetBrains/swaks) or real services to test.

```bash
swaks --to pager@example.com --server localhost:1025 < email.txt
```

---

## 📡 Webhook Delivery Format

The `parser` sends structured JSON like:

```json
{
  "from": "alerts@system.local",
  "to": "pager@example.com",
  "subject": "Critical alert",
  "text": "Something went wrong."
}
```

This is POSTed to your `WEBHOOK_URL`.

---

## 🩺 Health Check

Each container has a `/health` endpoint:

```bash
curl http://localhost:4000/health
```

---

## 🔁 Maintenance Scripts

| Script         | Description                             |
|----------------|-----------------------------------------|
| `setup.sh`     | Full automated setup                    |
| `reset.sh`     | Remove containers, logs, and data       |
| `uninstall.sh` | Purge everything                        |
| `diagnose.sh`  | Show status of all containers and ports |

---

## 🧰 Folder Structure

```
SMTPHook-Golang-main/
├── Makefile                     # Build automation script for Go services
├── README.md                    # Project documentation (this file)
├── diagnose.sh                  # Diagnostic script to check services, logs, ports
├── etc/                         # System configuration files
│   └── quadlet/                 # Quadlet container definitions for systemd + Podman
│       ├── container-parser.container
│       ├── container-smtp.container
│       ├── container-webhook-server.container
│       ├── container-webhook.container
│       └── smtphook.net         # Podman network definition
├── mailpit/                     # Optional Mailpit Dockerfile if custom build is needed
│   └── Dockerfile
├── parser/                      # Email parser service
│   ├── .env.example             # Example environment config
│   ├── Dockerfile               # Container build file
│   ├── go.mod                   # Go module file
│   └── main.go                  # Main logic to parse email and forward as JSON
├── podman-compose.yml           # Podman-compatible Docker Compose file for dev/test
├── reset.sh                     # Cleanup script: removes all containers and files
├── run.sh                       # Manual launcher (non-systemd)
├── sample-email.json            # Example of parsed email JSON payload
├── setup.sh                     # Full automatic installer and builder
├── uninstall.sh                 # Full uninstaller for the app
├── webhook-server/              # Production-grade webhook receiver with retry logic and action hooks
│   ├── .env.example             # Environment file to configure listening port and logging paths
│   ├── Dockerfile               # Container setup for deployment in Podman or Docker
│   ├── go.mod                   # Module definition including required libraries
│   └── main.go                  # Accepts parsed emails, logs them, performs configured actions (e.g. alerting)
├── webhook/                     # Lightweight development-only webhook that logs parsed emails
│   ├── .env.example             # Environment variables for port config, logging, etc.
│   ├── Dockerfile               # Container definition to run the test webhook in isolation
│   ├── go.mod                   # Go module definition for dependencies
│   └── main.go                  # Receives POST requests from parser, logs output to console
```

---

## 🧩 Integration Tip

Point `WEBHOOK_URL` in `.env` to any API that supports JSON input. For example:

- PagerDuty Events API
- Opsgenie Alert API
- Your own HTTP service

Use an adapter if needed to convert the payload format.

---

## License

MIT
