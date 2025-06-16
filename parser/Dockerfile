FROM golang:1.22-alpine

WORKDIR /app

COPY . .

RUN go build -o parser

VOLUME [ "/app/logs" ]

CMD ["./parser"]
