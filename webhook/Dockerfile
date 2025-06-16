FROM golang:1.21-alpine

WORKDIR /app
COPY . .

RUN go build -o webhook main.go

CMD ["./webhook"]
