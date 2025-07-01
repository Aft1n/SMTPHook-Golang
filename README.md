# SMTPHook

## ☕ Support

If you find this project useful, consider buying me a coffee:

[![Donate](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow)](https://coff.ee/voidwatch)

# SMTPHook

SMTPHook is a self-hosted email parsing pipeline written in Go. It converts emails into structured JSON and forwards them to an HTTP webhook.

This repository supports two separate modes:

1. **Parser-only production setup** (recommended)
2. **Full development environment** (includes webhook receiver and test SMTP)

---

## 1. Production Setup (Parser-Only)

If you're only interested in receiving and forwarding parsed email, use the `setup-parser.sh` script. This is the **simplest, containerized production setup**.

### Requirements:
- Linux with root access (Debian, Ubuntu, Fedora, Arch, etc.)
- Podman (Docker alternative)
- `pipx` to install `podman-compose`

### Steps:

```bash
chmod +x setup-parser.sh
./setup-parser.sh
```

This script will:
- Install `podman`, `podman-compose`, `pipx`
- Set up a `.env` file from `parser/.env.production.example`
- Create `mail/inbox` and `logs/` directories
- Prompt you to configure `.env`

Afterward, start the parser with:

```bash
podman-compose -f podman-compose-prod.yml up -d
```

### Example `.env`

```env
POLL_INTERVAL=5
WEBHOOK_URL=https://your.api/webhook
MAIL_DIR=/mail/inbox
```

### Volumes

Your `podman-compose-prod.yml` mounts:

```yaml
volumes:
  - ./mail/inbox:/mail/inbox:Z
  - ./logs:/logs:Z
```

Place `.eml` test files in `mail/inbox/` to simulate incoming email.

---

### Important: Systemd Quadlet is Not Supported with Podman Compose

If you're using `setup-parser.sh` and `podman-compose`, **do not use Quadlet `.container` files**. They are not compatible with the 3.4.x `podman-compose` and may cause conflicts.

---

## 2. Full Development Setup

If you're contributing to SMTPHook or testing it locally, use `setup.sh` instead.

This will:
- Install all development dependencies
- Build `parser`, `webhook`, and `webhook-server`
- Enable local testing via `mailpit` and mock webhooks

```bash
chmod +x setup.sh
./setup.sh
```

Start all dev services with:

```bash
podman-compose -f podman-compose.yml up --build
```

---

## 3. Script Summary

| Script              | Purpose                               |
|---------------------|---------------------------------------|
| `setup-parser.sh`   | Minimal production setup (parser only)|
| `setup.sh`          | Full dev setup                        |
| `run-prod.sh`       | Run parser using podman-compose       |
| `reset-prod.sh`     | Stop and clean parser environment     |
| `uninstall-prod.sh` | Clean up systemd (if used manually)   |
| `start-production.sh` | Wrapper to manage prod lifecycle    |

---

## 4. Folder Structure

```
SMTPHook-Golang/
├── parser/                  # Main parser service
│   ├── main.go              # Parses mail and sends JSON to webhook
│   ├── .env.production.example
│   └── Dockerfile
├── setup-parser.sh          # Parser-only setup (recommended)
├── setup.sh                 # Dev setup
├── podman-compose-prod.yml  # For production use
├── podman-compose.yml       # For development stack
├── mail/inbox/              # Drop .eml files here
├── logs/                    # Log output from parser
```

---

## 5. License

MIT

---

## 6. Contributions

Pull requests and improvements are welcome. Please use `setup.sh` for dev testing and lint your Go code before submitting.
