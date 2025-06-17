package main

import (
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

	logPath := os.Getenv("LOG_FILE_PATH")
	if logPath == "" {
		logPath = "logs/webhook.log"
	}

	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("Error opening log file: %v", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	log.Println("Webhook service starting on port", port)

	http.HandleFunc("/email", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST supported", http.StatusMethodNotAllowed)
			return
		}

		body := make([]byte, r.ContentLength)
		_, err := r.Body.Read(body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusInternalServerError)
			log.Println("Failed to read body:", err)
			return
		}
		r.Body.Close()

		log.Printf("[%s] Received email payload:\n%s\n", time.Now().Format(time.RFC3339), string(body))
		w.WriteHeader(http.StatusOK)
	})

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
