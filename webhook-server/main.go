package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

const logFilePath = "logs/received_emails.log"

type EmailPayload struct {
	From    string `json:"from"`
	To      string `json:"to"`
	Subject string `json:"subject"`
	Body    string `json:"body"`
	Date    string `json:"date"`
}

func main() {
	// Ensure log directory exists
	if err := os.MkdirAll("logs", os.ModePerm); err != nil {
		log.Fatalf("Failed to create logs directory: %v", err)
	}

	http.HandleFunc("/webhook", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
			return
		}

		var email EmailPayload
		err := json.NewDecoder(r.Body).Decode(&email)
		if err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		entry := fmt.Sprintf("[%s] From: %s | To: %s | Subject: %s | Body: %s\n",
			time.Now().Format(time.RFC3339),
			email.From, email.To, email.Subject, email.Body)

		// Append to log file
		f, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Printf("Failed to write log: %v", err)
			http.Error(w, "Internal error", http.StatusInternalServerError)
			return
		}
		defer f.Close()

		f.WriteString(entry)
		w.WriteHeader(http.StatusOK)
	})

	log.Println("Webhook server running on :4000")
	log.Fatal(http.ListenAndServe(":4000", nil))
}
