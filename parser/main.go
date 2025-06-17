package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/joho/godotenv"
)

type ParsedEmail struct {
	Subject string `json:"subject"`
	From    string `json:"from"`
	To      string `json:"to"`
	Date    string `json:"date"`
	Body    string `json:"body"`
}

type LogEntry struct {
	Timestamp string      `json:"timestamp"`
	Service   string      `json:"service"`
	Event     string      `json:"event"`
	Data      ParsedEmail `json:"data"`
}

func parseEmail(input string) ParsedEmail {
	var subject, from, to, date, body string
	scanner := bufio.NewScanner(strings.NewReader(input))

	readBody := false
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			readBody = true
			continue
		}
		if !readBody {
			if strings.HasPrefix(line, "Subject:") {
				subject = strings.TrimSpace(strings.TrimPrefix(line, "Subject:"))
			} else if strings.HasPrefix(line, "From:") {
				from = strings.TrimSpace(strings.TrimPrefix(line, "From:"))
			} else if strings.HasPrefix(line, "To:") {
				to = strings.TrimSpace(strings.TrimPrefix(line, "To:"))
			} else if strings.HasPrefix(line, "Date:") {
				date = strings.TrimSpace(strings.TrimPrefix(line, "Date:"))
			}
		} else {
			body += line + "\n"
		}
	}

	return ParsedEmail{
		Subject: subject,
		From:    from,
		To:      to,
		Date:    date,
		Body:    strings.TrimSpace(body),
	}
}

func postWithRetry(url string, data []byte, maxRetries int, delay time.Duration) error {
	for attempt := 1; attempt <= maxRetries; attempt++ {
		resp, err := http.Post(url, "application/json", bytes.NewBuffer(data))
		if err == nil && resp.StatusCode >= 200 && resp.StatusCode < 300 {
			resp.Body.Close()
			return nil
		}
		if resp != nil {
			resp.Body.Close()
		}
		log.Printf("Attempt %d failed. Retrying in %s...", attempt, delay)
		time.Sleep(delay)
	}
	return fmt.Errorf("all %d attempts to POST failed", maxRetries)
}

func startHealthServer(port string) {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})
	go func() {
		log.Printf("✅ Health check endpoint running at :%s/health", port)
		if err := http.ListenAndServe(":"+port, nil); err != nil {
			log.Fatalf("Health check server error: %v", err)
		}
	}()
}

func main() {
	_ = os.MkdirAll("logs", 0755)

	_ = godotenv.Load()

	logFilePath := os.Getenv("LOG_FILE_PATH")
	if logFilePath == "" {
		logFilePath = "logs/parser.log"
	}
	logFile, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatalf("❌ Could not open log file: %v", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	inputFile := os.Getenv("EMAIL_INPUT_FILE")
	webhookURL := os.Getenv("WEBHOOK_URL")
	pollInterval := os.Getenv("POLL_INTERVAL")
	if pollInterval == "" {
		pollInterval = "10"
	}
	intervalSec, _ := time.ParseDuration(pollInterval + "s")

	healthPort := os.Getenv("HEALTH_PORT")
	if healthPort == "" {
		healthPort = "4010"
	}
	startHealthServer(healthPort)

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	log.Println("📬 Parser service started. Watching for email input every", intervalSec)

loop:
	for {
		select {
		case <-stop:
			log.Println("🛑 Shutting down parser...")
			break loop
		default:
			var rawInput string
			if inputFile != "" {
				data, err := os.ReadFile(inputFile)
				if err != nil {
					log.Printf("⚠️ Failed to read input file: %v", err)
					time.Sleep(intervalSec)
					continue
				}
				if len(data) == 0 {
					time.Sleep(intervalSec)
					continue
				}
				rawInput = string(data)
				_ = os.Truncate(inputFile, 0)
			} else {
				data, err := io.ReadAll(os.Stdin)
				if err != nil {
					log.Printf("⚠️ Failed to read from stdin: %v", err)
					time.Sleep(intervalSec)
					continue
				}
				rawInput = string(data)
			}

			email := parseEmail(rawInput)
			entry := LogEntry{
				Timestamp: time.Now().Format(time.RFC3339),
				Service:   "parser",
				Event:     "parsed_email",
				Data:      email,
			}

			jsonData, err := json.MarshalIndent(entry, "", "  ")
			if err != nil {
				log.Printf("❌ Failed to encode JSON: %v", err)
				continue
			}

			log.Println(string(jsonData))
			fmt.Println(string(jsonData))

			if webhookURL != "" {
				if err := postWithRetry(webhookURL, jsonData, 5, 5*time.Second); err != nil {
					log.Printf("❌ Failed to POST to webhook: %v", err)
				} else {
					log.Println("✅ Posted to webhook.")
				}
			}
			time.Sleep(intervalSec)
		}
	}

	log.Println("👋 Parser service stopped gracefully.")
}
