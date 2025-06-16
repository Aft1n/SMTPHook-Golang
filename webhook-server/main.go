package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

type Email struct {
	Subject string `json:"subject"`
	From    string `json:"from"`
	To      string `json:"to"`
	Date    string `json:"date"`
	Body    string `json:"body"`
}

type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Service   string `json:"service"`
	Event     string `json:"event"`
	Data      Email  `json:"data"`
}

func writeLog(entry LogEntry) {
	file, err := os.OpenFile("logs/webhook.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
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

func emailHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "invalid method", http.StatusMethodNotAllowed)
		return
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "failed to read body", http.StatusInternalServerError)
		return
	}

	var email Email
	if err := json.Unmarshal(body, &email); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	entry := LogEntry{
		Timestamp: time.Now().Format("2006-01-02 15:04:05 MST"),
		Service:   "webhook",
		Event:     "email_received",
		Data:      email,
	}
	writeLog(entry)
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Email received and logged")
}

func main() {
	http.HandleFunc("/email", emailHandler)
	fmt.Println("Webhook server running on port 4000")
	log.Fatal(http.ListenAndServe(":4000", nil))
}
