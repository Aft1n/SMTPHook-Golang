# docker-compose.yml or podman-compose.yml section (already containerized)
  smtp:
    image: axllent/mailpit
    container_name: mailpit
    ports:
      - "1025:1025"   # SMTP
      - "8025:8025"   # Web UI/API
    restart: unless-stopped
    volumes:
      - ./logs:/data
