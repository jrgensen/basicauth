package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
)

var users map[string]string

func main() {
	fmt.Println("Starting basicauth service")

	users = make(map[string]string, 0)
	for _, line := range strings.Fields(os.Getenv("USERPASS")) {
		userpass := strings.SplitN(line, ":", 2)
		users[userpass[0]] = userpass[1]
	}
	log.Printf("%#v\n", users)

	http.HandleFunc("/", basicAuth(OkHandler))

	fmt.Println("Running webserver")
	log.Fatal(http.ListenAndServe(":80", nil))
}

func basicAuth(h http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, pass, _ := r.BasicAuth()

		if _, found := users[user]; !found || users[user] != pass {
			w.Header().Set("WWW-Authenticate", `Basic realm="Restricted"`)
			http.Error(w, "Unauthorized.", http.StatusUnauthorized)
			return
		}

		h.ServeHTTP(w, r)
	})
}

func OkHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "OK")
}
