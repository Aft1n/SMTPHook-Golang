package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
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
	http.HandleFunc("/ingest", ingestHandler)
	log.Println("Webhook listening on :4000")
	if err := http.ListenAndServe(":4000", nil); err != nil {
		log.Fatal("Server error:", err)
	}
}
