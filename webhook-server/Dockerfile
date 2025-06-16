FROM golang:1.22-alpine

WORKDIR /app

COPY . .

RUN go build -o webhook-server

VOLUME [ "/app/logs" ]

CMD ["./webhook-server"]
