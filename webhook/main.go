package main

import (
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "4000"
	}

	// Log to stdout (default)
	log.SetOutput(os.Stdout)
	log.Println("Webhook service starting on port", port)

	http.HandleFunc("/email", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST supported", http.StatusMethodNotAllowed)
			return
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			log.Println("Failed to read body:", err)
			return
		}
		defer r.Body.Close()

		log.Printf("[%s] Received email payload:\n%s\n", time.Now().Format(time.RFC3339), string(body))
		w.WriteHeader(http.StatusOK)
	})

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
