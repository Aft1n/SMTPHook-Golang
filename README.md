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
