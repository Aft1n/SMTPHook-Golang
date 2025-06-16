// parser/main.go
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
	ID       string `json:"ID"`
	From     string `json:"From"`
	To       string `json:"To"`
	Subject  string `json:"Subject"`
	Body     string `json:"Text"`
	Received string `json:"Created"`
}

func fetchEmails(apiURL string) ([]Email, error) {
	resp, err := http.Get(apiURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch emails: %s", resp.Status)
	}

	var emails []Email
	if err := json.NewDecoder(resp.Body).Decode(&emails); err != nil {
		return nil, err
	}
	return emails, nil
}

func forwardEmail(email Email, webhookURL string) error {
	body, err := json.Marshal(email)
	if err != nil {
		return err
	}

	resp, err := http.Post(webhookURL, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		b, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("webhook error %d: %s", resp.StatusCode, string(b))
	}

	return nil
}

func main() {
	mailpitAPI := os.Getenv("MAILPIT_API")           // e.g., http://mailpit:8025/api/v1/messages
	webhookURL := os.Getenv("WEBHOOK_URL")           // e.g., http://webhook-server:4000/webhook
	pollInterval := 10 * time.Second

	if mailpitAPI == "" || webhookURL == "" {
		log.Fatal("MAILPIT_API and WEBHOOK_URL must be set")
	}

	log.Println("Starting email parser...")

	seen := make(map[string]bool)

	for {
		emails, err := fetchEmails(mailpitAPI)
		if err != nil {
			log.Printf("Error fetching emails: %v", err)
			time.Sleep(pollInterval)
			continue
		}

		for _, email := range emails {
			if seen[email.ID] {
				continue
			}

			if err := forwardEmail(email, webhookURL); err != nil {
				log.Printf("Failed to forward email %s: %v", email.ID, err)
			} else {
				log.Printf("Forwarded email %s to webhook", email.ID)
				seen[email.ID] = true
			}
		}

		time.Sleep(pollInterval)
	}
}
