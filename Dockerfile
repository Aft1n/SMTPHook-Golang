# syntax=docker/dockerfile:1
FROM golang:1.22-alpine AS builder

WORKDIR /app
# Copy only parser source
COPY parser ./parser

# Build the parser binary
WORKDIR /app/parser
RUN go mod tidy && go build -o /app/smtphook .

# ─────────────── RUNTIME IMAGE ───────────────
FROM alpine:3.19

WORKDIR /app
COPY --from=builder /app/smtphook .
RUN mkdir -p /mail/inbox /logs

ENV POLL_INTERVAL=5
ENV WEBHOOK_URL=https://your.api/webhook
ENV MAIL_DIR=/mail/inbox

CMD ["./smtphook"]
