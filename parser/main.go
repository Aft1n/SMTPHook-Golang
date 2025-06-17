package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
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
			switch {
			case strings.HasPrefix(line, "Subject:"):
				subject = strings.TrimSpace(strings.TrimPrefix(line, "Subject:"))
			case strings.HasPrefix(line, "From:"):
				from = strings.TrimSpace(strings.TrimPrefix(line, "From:"))
			case strings.HasPrefix(line, "To:"):
				to = strings.TrimSpace(strings.TrimPrefix(line, "To:"))
			case strings.HasPrefix(line, "Date:"):
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

func main() {
	_ = os.MkdirAll("logs", 0755)

	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found or error loading it.")
	}

	inputFile := os.Getenv("EMAIL_INPUT_FILE")
	logFilePath := os.Getenv("LOG_FILE_PATH")
	if logFilePath == "" {
		logFilePath = "logs/parser.log"
	}
	pollInterval := 10 * time.Second
	if v := os.Getenv("EMAIL_POLL_INTERVAL"); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			pollInterval = d
		}
	}

	logFile, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatalf("Could not open log file: %v", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	log.Println("Parser service started. Polling every", pollInterval)

	for {
		var rawInput string
		if inputFile != "" {
			data, err := os.ReadFile(inputFile)
			if err == nil && len(data) > 0 {
				rawInput = string(data)

				email := parseEmail(rawInput)
				entry := LogEntry{
					Timestamp: time.Now().Format(time.RFC3339),
					Service:   "parser",
					Event:     "parsed_email",
					Data:      email,
				}

				jsonData, err := json.MarshalIndent(entry, "", "  ")
				if err == nil {
					log.Println(string(jsonData))
					fmt.Println(string(jsonData))
				}

				// clear file after reading
				_ = os.WriteFile(inputFile, []byte{}, 0644)
			}
		} else {
			// fallback to stdin if no EMAIL_INPUT_FILE is specified
			data, err := io.ReadAll(os.Stdin)
			if err == nil && len(data) > 0 {
				rawInput = string(data)

				email := parseEmail(rawInput)
				entry := LogEntry{
					Timestamp: time.Now().Format(time.RFC3339),
					Service:   "parser",
					Event:     "parsed_email",
					Data:      email,
				}

				jsonData, err := json.MarshalIndent(entry, "", "  ")
				if err == nil {
					log.Println(string(jsonData))
					fmt.Println(string(jsonData))
				}
			}
			break // if stdin was used, run once and exit
		}

		time.Sleep(pollInterval)
	}
}
