package main

import (
	"net/http"
	"log"
)

func HelloServer(w http.ResposeWriter, req *http.Request){
	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte("This is an example server.\n"))
}

func main() {
	http.HandleFunc("/hello", HelloServer)
	err := http.ListenAndServerTLS(":443", "server.crt", "server.key", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}