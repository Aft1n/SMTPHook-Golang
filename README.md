# SMTPHook

SMTPHook is a modular and containerized platform to receive, parse, and forward emails to webhooks. It is written entirely in Go, uses Podman (or Docker) and is ready with systemd and logrotate support.

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
│   └── system/systemd/  # systemd service units for each component
├── podman-compose.yml   # Container orchestration
└── README.md            # You are here
```

---

## 🚀 Quick Start (Using Podman Compose)

### 1. Prerequisites

- [Go 1.21+](https://go.dev/dl/) (required to build services)
- [Podman](https://podman.io/) and [podman-compose](https://github.com/containers/podman-compose)
- `git`, `make`, and `systemd` (for development and deployment)


- [Podman](https://podman.io/) and [podman-compose](https://github.com/containers/podman-compose)
- `git` and `make` (optional but useful)
- Linux system with `systemd` (for system services)

### 2. Clone the Repository

```bash
git clone https://your-repo-url/SMTPHook-Golang-main.git
cd SMTPHook-Golang-main
```

### 3. Configure `.env` files

Each service has a `.env.example`. Create real `.env` files:

```bash
cp parser/.env.example parser/.env
cp webhook/.env.example webhook/.env
cp webhook-server/.env.example webhook-server/.env
```

Adjust values if needed (ports, log paths, etc.)

---

### 4. Build All Services

```bash
podman-compose -f podman-compose.yml build
```

### 5. Run the Stack

```bash
podman-compose -f podman-compose.yml up
```

> The following ports are used:
> - Mailpit SMTP: `1025`
> - Mailpit Web UI: `8025`
> - Webhook: `4000`
> - Webhook-server: `4000`

---

## 🛠️ Manual Build (without containers)

Install Go dependencies first:
```bash
go mod tidy
```


You can build each Go service manually:

```bash
cd parser
go build -o ../bin/parser

cd ../webhook
go build -o ../bin/webhook

cd ../webhook-server
go build -o ../bin/webhook-server
```

Run each manually or via systemd (see below).

---

## 🧩 Systemd Setup

To install system-wide services:

```bash
sudo cp etc/system/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable smtphook.service
sudo systemctl start smtphook.service
```

Adjust each service if paths to binaries or working directories differ.

---

## 🧹 Log Rotation

Log files are written to `logs/*.log` by default.

Ensure logrotate is configured:

```bash
sudo cp etc/logrotate.d/smtphook /etc/logrotate.d/
```

Check logs:
```bash
tail -f logs/webhook.log
```

---

## 🧪 Testing

### Test Email Input

You can send a fake email to `Mailpit` using any SMTP client:

```bash
swaks --to test@example.com --server localhost:1025 --data email.txt
```

### Test Webhook Handler

```bash
curl -X POST http://localhost:4000/email      -H "Content-Type: application/json"      -d @sample-email.json
```

---

## 📂 Environment Variable Reference

| Service         | Variable         | Default Value          | Description                          |
|-----------------|------------------|-------------------------|--------------------------------------|
| All             | `PORT`           | `4000`                  | Port the service listens on          |
| All             | `LOG_FILE_PATH`  | `logs/*.log`            | Path to log output                   |
| parser          | `EMAIL_INPUT_FILE` | (empty)              | Path to raw email input file (or use stdin) |

---

## 📎 Notes

- Use `podman-compose` or `docker-compose` depending on your environment.
- Make sure `logs/` directory exists or is writable before starting.
- `Mailpit` is included for local SMTP testing and can be removed in production.

---

## 📜 License

MIT — free to use, modify, and distribute.

---

## 🙋 FAQ

**Q: Can I use Docker instead of Podman?**  
Yes. Just replace `podman-compose` with `docker-compose`.

**Q: Is this production ready?**  
Yes, with systemd, logrotate, and modular components, it is designed for long-running environments.

**Q: Does this use any external databases?**  
No — logs are written to files for simplicity.

---

## 🤝 Contributing

Pull requests and issues are welcome! Please file bugs or feature requests via GitHub Issues.
