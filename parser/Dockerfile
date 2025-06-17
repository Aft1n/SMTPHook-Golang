FROM golang:1.21-alpine

WORKDIR /app

# Optimize build cache
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build binary
RUN go build -o main

# Optional default env (can be overridden by `.env`)
ENV PORT=4000
ENV LOG_FILE_PATH=logs/output.log

# Create logs dir
RUN mkdir -p /app/logs

CMD ["./main"]
