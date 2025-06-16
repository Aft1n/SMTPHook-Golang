package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
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

func writeLog(entry LogEntry) {
	file, err := os.OpenFile("logs/parser.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
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
	input := `Subject: Hello
From: test@example.com
To: recipient@example.com
Date: Mon, 16 Jun 2025 14:00:00 +0200

This is a test email body.`

	email := parseEmail(input)
	entry := LogEntry{
		Timestamp: time.Now().Format("2006-01-02 15:04:05 MST"),
		Service:   "parser",
		Event:     "parsed_email",
		Data:      email,
	}
	writeLog(entry)
	fmt.Println("Email parsed and logged.")
}
