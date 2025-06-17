package main

import (
	"bufio"
	"encoding/json"
	"fmt"
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
	scanner := bufio.NewScanner(strings.NewReader(input))
	email := ParsedEmail{}
	bodyLines := []string{}
	isBody := false

	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			isBody = true
			continue
		}
		if isBody {
			bodyLines = append(bodyLines, line)
		} else if strings.HasPrefix(line, "Subject:") {
			email.Subject = strings.TrimPrefix(line, "Subject: ")
		} else if strings.HasPrefix(line, "From:") {
			email.From = strings.TrimPrefix(line, "From: ")
		} else if strings.HasPrefix(line, "To:") {
			email.To = strings.TrimPrefix(line, "To: ")
		} else if strings.HasPrefix(line, "Date:") {
			email.Date = strings.TrimPrefix(line, "Date: ")
		}
	}
	email.Body = strings.Join(bodyLines, "\n")
	return email
}

func writeLog(entry LogEntry, logPath string) {
	file, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatalf("error opening log file: %v", err)
	}
	defer file.Close()

	jsonData, err := json.Marshal(entry)
	if err != nil {
		log.Printf("error marshaling log entry: %v", err)
		return
	}
	file.WriteString(string(jsonData) + "\n")
}

func main() {
    // Create logs/ directory if it doesn't exist
    err := os.MkdirAll("logs", 0755)
    if err != nil {
        log.Fatalf("Failed to create logs directory: %v", err)
    }
	_ = godotenv.Load()

	logPath := os.Getenv("LOG_FILE_PATH")
	if logPath == "" {
		log.Fatal("LOG_FILE_PATH not set in .env")
	}

	inputFile := os.Getenv("EMAIL_INPUT_FILE")
	var input string

	if inputFile != "" {
		content, err := os.ReadFile(inputFile)
		if err != nil {
			log.Fatalf("failed to read input file: %v", err)
		}
		input = string(content)
	} else {
		fmt.Println("Reading email from stdin (end with Ctrl+D):")
		stdinBytes, err := io.ReadAll(os.Stdin)
		if err != nil {
			log.Fatalf("failed to read from stdin: %v", err)
		}
		input = string(stdinBytes)
	}

	email := parseEmail(input)
	entry := LogEntry{
		Timestamp: time.Now().Format("2006-01-02 15:04:05 MST"),
		Service:   "parser",
		Event:     "parsed_email",
		Data:      email,
	}
	writeLog(entry, logPath)
	fmt.Println("Email parsed and logged.")
}
