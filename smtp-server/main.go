package main

import (
	"log/slog"
	"os"
)

func main() {
	logFile, err := os.OpenFile("logs/smtp.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		panic(err)
	}
	logger := slog.New(slog.NewJSONHandler(logFile, nil))
	slog.SetDefault(logger)

	slog.Info("SMTP server starting")
	// ...
}
