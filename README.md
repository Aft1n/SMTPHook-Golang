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
git clone https://github.com/your-user/SMTPHook-Golang.git
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
SMTPHook-Golang/
├── parser/            # Polls, parses and sends email JSON
├── webhook/           # Test webhook server
├── webhook-server/    # Production webhook consumer
├── etc/quadlet/       # Quadlet container definitions
├── logs/              # Log output
├── email.txt          # Sample test message
├── sample-email.json  # Webhook sample payload
├── setup.sh           # Main install script
└── ...
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
