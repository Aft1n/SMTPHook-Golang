FROM golang:1.21-alpine

WORKDIR /app
COPY . .

RUN go build -o parser main.go

CMD ["./parser"]
