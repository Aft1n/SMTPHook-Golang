# SMTPHook

SMTPHook is a modular and containerized platform to receive, parse, and forward emails to webhooks. It is written entirely in Go, uses Podman (or Docker), and supports systemd and logrotate for production readiness.

---

## 🔧 Project Structure

```
SMTPHook-Golang-main/
├── parser/              # Parses incoming emails into structured JSON logs
├── webhook/             # Receives structured emails via POST (for testing ingestion)
├── webhook-server/      # HTTP server that receives parsed emails and writes logs
├── mailpit/             # SMTP capture and debugging via Mailpit
├── etc/
│   ├── logrotate.d/     # Log rotation configs
│   └── system/systemd/  # systemd unit files
├── podman-compose.yml   # Container orchestration
├── Makefile             # Build & install automation
├── run.sh               # Quick start script
└── README.md            # You are here
```

---

## 🚀 Quick Start

### 1. Prerequisites

- [Go 1.21+](https://go.dev/dl/)
- [Podman](https://podman.io/) and [podman-compose](https://github.com/containers/podman-compose)
- `make`, `systemd`, and `git` (for build and deployment)

---

### 2. Clone and Launch

```bash
git clone git@github.com:voidwatch/SMTPHook-Golang.git
cd SMTPHook-Golang
chmod +x run.sh
./run.sh
```

> This ensures:
> - All `.env` files are created if missing
> - All services are built into `bin/`
> - Stack is started via `podman-compose`

---

## 🛠️ Manual Build & Install

To build all services:
```bash
make
```

To install binaries into `/opt/smtphook/bin`:
```bash
sudo make install
```

---

## 🧩 Systemd Setup (Optional)

```bash
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo cp etc/system/systemd/smtphook.target /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable smtphook.target
sudo systemctl start smtphook.target
```

---

## 🧹 Log Rotation

```bash
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/
```

Log files are written to `logs/*.log`. They are rotated daily with compression.

---

## 🧪 Testing

### Send a fake email

```bash
swaks --to test@example.com --server localhost:1025 --data email.txt
```

### Test the webhook directly

```bash
curl -X POST http://localhost:4000/email -H "Content-Type: application/json" -d @sample-email.json
```

---

## 📂 Environment Variable Reference

| Service         | Variable            | Default Value    | Description                          |
|-----------------|---------------------|------------------|--------------------------------------|
| All             | `PORT`              | `4000`           | Port the service listens on          |
| All             | `LOG_FILE_PATH`     | `logs/*.log`     | Path to log output                   |
| parser          | `EMAIL_INPUT_FILE`  | (empty)          | Path to raw email input file         |

---

## 📎 Notes

- `podman-compose` or `docker-compose` can be used interchangeably.
- `logs/` directory is automatically created if it does not exist.
- `Mailpit` is provided for local SMTP testing and is optional in production.

---

## 📜 License

MIT — free to use, modify, and distribute.

---

## 🙋 FAQ

**Q: Can I use Docker instead of Podman?**  
Yes. Just replace `podman-compose` with `docker-compose`.

**Q: Is this production ready?**  
Yes — with systemd, logrotate, and isolated components, it’s designed for long-running environments.

**Q: Does this use any external databases?**  
No — logs are written to files for simplicity.

---

## 🤝 Contributing

Pull requests and issues are welcome! Please file bugs or feature requests via GitHub Issues.


---

## 🔁 Internal Request Flow

Here’s how the components communicate internally:

1. **Mailpit** receives raw SMTP email on port `1025`.
2. `parser` fetches emails (either from Mailpit API or stdin/file) and converts them to structured JSON.
3. The structured output is sent via HTTP POST to the `webhook` endpoint (http://webhook:4000/email).
4. `webhook` forwards the parsed data to `webhook-server`, or logs it directly to file for ingestion testing.

> The `parser` acts as the central translation engine between raw SMTP and structured webhook JSON.

---

## 📡 API Contract (Webhook)

### POST `/email`

Used by `parser` to send structured email data.

#### Request Body (application/json)

```json
{
  "from": "example@domain.com",
  "to": ["recipient@domain.com"],
  "subject": "Test Email",
  "body": "This is a test message.",
  "timestamp": "2025-06-17T12:34:56Z"
}
```

#### Response

- `200 OK`: Accepted
- `400 Bad Request`: Malformed payload
- `500 Internal Server Error`: Downstream failure

---

## 🐞 Debugging Tips

### 1. View Service Logs

If using containers:
```bash
podman logs parser
podman logs webhook
podman logs webhook-server
```

If using systemd:
```bash
journalctl -u parser.service -f
```

### 2. Verify HTTP Requests

Use curl or a tool like Postman:
```bash
curl -X POST http://localhost:4000/email -H "Content-Type: application/json" -d @sample-email.json
```

### 3. Inspect Log Files

Logs are written to `logs/`:
```bash
tail -f logs/parser.log
tail -f logs/webhook.log
```

### 4. Common Issues

| Symptom | Likely Cause | Fix |
|--------|---------------|-----|
| No logs generated | `logs/` missing or unwritable | `mkdir -p logs/` |
| 400 error on webhook | Malformed JSON payload | Validate structure |
| Container crash | Missing `.env` or port conflict | Check `.env` values |

---

## 🧠 Developer Tips

- Build individual services locally with `go build -o bin/<name>` inside each subdirectory.
- Use `log.Println()` for temporary debug logging.
- Implement `/health` endpoint in each service for integration with health checks.



---

## 🔧 How to Configure SMTPHook for Your API

You can configure SMTPHook to forward parsed emails to **your own API endpoint** instead of the default internal webhook.

### Step 1: Edit `.env` for `parser`

In `parser/.env`:

```env
# Replace with your real API endpoint
WEBHOOK_URL=https://your-api.com/inbound-email
```

Make sure your API accepts `POST` requests with the following JSON structure:

```json
{
  "from": "sender@example.com",
  "to": ["your@domain.com"],
  "subject": "Sample Subject",
  "body": "Message body here",
  "timestamp": "ISO 8601 string"
}
```

### Step 2: Rebuild and Restart

If using containers:

```bash
podman-compose down
podman-compose up --build
```

If using systemd:

```bash
sudo systemctl restart smtphook.target
```

### Step 3: Verify Delivery

You should see POST requests from the `parser` service hitting your API. Check logs with:

```bash
tail -f logs/parser.log
```

### 🔐 Tips

- Make sure your API allows CORS and HTTPS if needed.
- Use authentication tokens in headers if your API requires it. Extend `parser` to support headers via `.env`.

Example:
```env
WEBHOOK_AUTH_HEADER=Authorization: Bearer YOUR_TOKEN
```

And modify `parser/main.go` to read and attach this header if defined.
