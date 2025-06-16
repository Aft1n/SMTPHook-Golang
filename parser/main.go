package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
	"time"
)

type MailpitMessage struct {
	ID      string `json:"ID"`
	Subject string `json:"Subject"`
	From    []struct {
		Address string `json:"Address"`
	} `json:"From"`
	Text string `json:"Text"`
}

type MailpitResponse struct {
	Messages []MailpitMessage `json:"messages"`
}

func fetchEmails() []MailpitMessage {
	resp, err := http.Get("http://mailpit:8025/api/v1/messages")
	if err != nil {
		log.Println("Error fetching emails:", err)
		return nil
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)

	var result MailpitResponse
	if err := json.Unmarshal(body, &result); err != nil {
		log.Println("Error parsing JSON:", err)
		return nil
	}
	return result.Messages
}

func forwardEmail(msg MailpitMessage) {
	payload := map[string]interface{}{
		"from":    msg.From[0].Address,
		"subject": msg.Subject,
		"body":    msg.Text,
	}
	data, _ := json.Marshal(payload)

	resp, err := http.Post("http://webhook:4000/ingest", "application/json", bytes.NewBuffer(data))
	if err != nil {
		log.Println("Failed to forward email:", err)
		return
	}
	defer resp.Body.Close()
	log.Printf("Forwarded: %s (%s)\n", msg.Subject, msg.From[0].Address)
}

func main() {
	seen := map[string]bool{}
	for {
		messages := fetchEmails()
		for _, msg := range messages {
			if seen[msg.ID] {
				continue
			}
			forwardEmail(msg)
			seen[msg.ID] = true
		}
		time.Sleep(5 * time.Second)
	}
}
