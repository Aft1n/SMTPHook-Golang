# SMTPHook

SMTPHook is a modular and containerized platform to receive, parse, and forward emails to webhooks. It is written in Go, supports Podman or Docker, and includes systemd units and logrotate config for production deployment.

---

## 🔧 Project Structure

```
SMTPHook-Golang/
├── parser/              # Converts raw SMTP email to structured JSON
├── webhook/             # Test endpoint to receive parsed JSON
├── webhook-server/      # Writes parsed JSON to logs or further handling
├── etc/
│   ├── logrotate.d/     # Logrotate config for logs/*.log
│   └── system/systemd/  # systemd unit files
├── podman-compose.yml   # Container orchestration
├── Makefile             # Build all services
├── setup.sh             # Full setup script (install, build, configure)
├── reset.sh             # Clean or purge installed state
└── README.md            # You are here
```

---

## 🚀 Quick Start

### 1. Prerequisites

Supported package managers:
- ✅ `apt` (Debian/Ubuntu)
- ✅ `dnf` (Fedora/RHEL/CentOS)
- ✅ `apk` (Alpine)

Required tools:
- Go 1.21+
- Podman or Docker
- pipx (for podman-compose)
- make, git, systemd

---

### 2. Setup with One Command

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Install required dependencies
- Run `go mod tidy` for all services
- Create `.env` files
- Build and install all services to `/opt/smtphook/`
- Install and start systemd services
- Configure logrotate
- Install `swaks` for email testing

> Requires `sudo` access.

---

## 🔁 Reset or Purge

To clean up the environment without uninstalling:

```bash
./reset.sh
```

To remove everything, including systemd units, logs, and binaries:

```bash
./reset.sh --purge
```

---

## 🧪 Testing

### Send test email into Mailpit:

```bash
swaks --to test@example.com --server localhost:1025 < email.txt
```

### Manually test webhook:

```bash
curl -X POST http://localhost:4000/email      -H "Content-Type: application/json"      -d @sample-email.json
```

---

## 🧹 Log Rotation

Logs are written to `logs/*.log` and rotated via systemd cron (daily with compression):

```bash
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/
```

---

## 🔁 Internal Request Flow

```
SMTP Email (Mailpit) --> parser --> webhook --> webhook-server --> logs/
```

1. Mailpit receives SMTP email on port `1025`.
2. `parser` reads and parses the email into JSON.
3. `parser` POSTs the structured payload to the `webhook` endpoint.
4. `webhook` forwards it to `webhook-server` or logs the result.

---

## 📡 API Contract (Webhook)

### POST `/email`

Example request:

```json
{
  "from": "sender@domain.com",
  "to": ["to@domain.com"],
  "subject": "Subject text",
  "body": "Message body",
  "timestamp": "2025-06-17T12:00:00Z"
}
```

### Responses

- `200 OK` – Accepted
- `400 Bad Request` – Invalid structure
- `500 Internal Server Error` – Server failure

---

## 🔧 Configure SMTPHook to Use Your API

1. Open `parser/.env` and change:

```env
WEBHOOK_URL=https://your-api.com/inbound-email
```

2. Optional auth:

```env
WEBHOOK_AUTH_HEADER=Authorization: Bearer YOUR_TOKEN
```

3. Rebuild or restart:

```bash
sudo systemctl restart smtphook.target
```

> The `parser` will now POST every structured email to your endpoint.

---

## 🐞 Debugging Tips

### Logs

```bash
journalctl -u parser.service -f
tail -f logs/parser.log
```

### Check services

```bash
systemctl status smtphook.target
podman ps
```

### Validate test email flow

```bash
swaks --to test@x.com --server localhost:1025 --data email.txt
```

---

## 📂 Environment Variable Reference

| Service         | Variable            | Default         | Description                     |
|-----------------|---------------------|------------------|---------------------------------|
| All             | `PORT`              | `4000`           | Service port                    |
| All             | `LOG_FILE_PATH`     | `logs/*.log`     | Log output file                 |
| parser          | `EMAIL_INPUT_FILE`  | (optional)       | Path to raw input               |
| parser          | `WEBHOOK_URL`       | http://webhook   | Destination API URL             |
| parser          | `WEBHOOK_AUTH_HEADER` | (optional)     | Auth header for outbound POSTs  |

---

## 🙋 FAQ

**Q: Can I use Docker instead of Podman?**  
Yes. Just replace `podman-compose` with `docker-compose`.

**Q: Is this production ready?**  
Yes — systemd units, logrotate, and isolated binaries included.

**Q: Is Mailpit required in production?**  
No — it's for local testing only. Disable it in `podman-compose.yml` if not needed.

---

## 🤝 Contributing

Feel free to file issues or send PRs. All feedback and patches are welcome.

---

## 📜 License

MIT — free to use, fork, and redistribute.
