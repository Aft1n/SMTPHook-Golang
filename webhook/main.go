package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

type EmailPayload struct {
	From    string `json:"from"`
	Subject string `json:"subject"`
	Body    string `json:"body"`
}

func ingestHandler(w http.ResponseWriter, r *http.Request) {
	var payload EmailPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}
	log.Printf("Email received from %s: %s\n---\n%s\n", payload.From, payload.Subject, payload.Body)
	w.WriteHeader(http.StatusNoContent)
}

func main() {
    // Create logs/ directory if it doesn't exist
    err := os.MkdirAll("logs", 0755)
    if err != nil {
        log.Fatalf("Failed to create logs directory: %v", err)
    }
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "4000"
	}

	http.HandleFunc("/ingest", ingestHandler)
	log.Printf("Webhook listening on :%s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("Server error:", err)
	}
}
