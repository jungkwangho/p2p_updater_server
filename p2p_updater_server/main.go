package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

func HelloServer(w http.ResponseWriter, req *http.Request) {

	result := 0
	if req.Method == "POST" {
		result = -1
	}

	msg := "Server OK.\n"
	if result != 0 {
		msg = "Server Fail.\n"
	}

	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte(msg))
}

type UpdaterHandler struct {
	db   *sql.DB
	conf *Config
}

type UpdateCheckRequest struct {
	Type    string `json:"type"`
	Hash    string `json:"hash"`
	Name    string `json:"name"`
	Version string `json:"version"`
}

type UpdateCheckResponse struct {
	Result  int    `json:"result"`
	Msg     string `json:"msg"`
	Type    string `json:"type"`
	Hash    string `json:"hash"`
	Name    string `json:"name"`
	Version string `json:"version"`
}

func (updaterHandler *UpdaterHandler) UpdateCheck(w http.ResponseWriter, req *http.Request) {

	var check_req UpdateCheckRequest
	var check_res UpdateCheckResponse

	if req.Method == "GET" {
		check_res.Result = -1
		check_res.Msg = "invalid request 1"
	}

	err := json.NewDecoder(req.Body).Decode(&check_req)
	if err != nil {
		check_res.Result = -2
		check_res.Msg = "invalid request 2"
	}

	var old_info FileInfo
	old_info.Type = check_req.Type
	old_info.Version = check_req.Version
	old_info.Hash = check_req.Hash
	old_info.Name = check_req.Name
	update_info, err := GetUpdateInfo(updaterHandler.db, &old_info)
	if err != nil {
		check_res.Result = -2
		check_res.Msg = "no update exists"
	}

	check_res.Result = 0
	check_res.Msg = "update exists"
	check_res.Type = update_info.Type
	check_res.Version = update_info.Version
	check_res.Hash = update_info.Hash
	check_res.Name = update_info.Name

	json.NewEncoder(w).Encode(check_res)
}

type UpdateRequest struct {
	Hash string `json:"hash"`
}

func (updaterHander *UpdaterHandler) Update(w http.ResponseWriter, req *http.Request) {

	var update_req UpdateRequest

	if req.Method == "GET" {
		http.Error(w, "Bad Reuqest 1", 400)
		return
	}

	err := json.NewDecoder(req.Body).Decode(&update_req)
	if err != nil {
		http.Error(w, "Bad Reuqest 2", 400)
		return
	}

	stored_path, err := GetStoredPathByHash(updaterHander.db, update_req.Hash)
	if err != nil {
		http.Error(w, "Internal Error", 500)
		return
	}

	server_base := updaterHander.conf.ServerBase

	full_path := filepath.Join(server_base, stored_path)
	_, err = os.Stat(full_path)
	if err != nil {
		http.Error(w, "Not Found", 404)
		return
	}
	http.ServeFile(w, req, full_path)
}

type MinFileInfo struct {
	Type    string `json:"type"`
	Hash    string `json:"hash"`
	Name    string `json:"name"`
	Version string `json:"version"`
}

type ReportRequest struct {
	Old     MinFileInfo `json:"old"`
	New     MinFileInfo `json:"new"`
	UserId  string      `json:"user_id"`
	Ip      string      `json:"ip"`
	ErrCode string      `json:"err_code"`
	ErrMsg  string      `json:"err_msg"`
}

func (updaterHander *UpdaterHandler) Report(w http.ResponseWriter, req *http.Request) {
	var report_req ReportRequest

	if req.Method == "GET" {
		http.Error(w, "Bad Reuqest 1", 400)
		return
	}

	err := json.NewDecoder(req.Body).Decode(&report_req)
	if err != nil {
		http.Error(w, "Bad Reuqest 2", 400)
		return
	}

	err = InsertReport(updaterHander.db, &report_req.Old, &report_req.New, report_req.UserId, report_req.Ip, report_req.ErrCode, report_req.ErrMsg)
	if err != nil {
		http.Error(w, "Internal Error", 500)
		return
	}

	http.Error(w, "OK", 200)
}

func main() {
	var conf Config
	err := conf.Load("./config.json")
	if err != nil {
		log.Fatal("Load config failed: ", err)
	}

	db, err := OpenDB(conf.DBAddr, conf.DBPort, conf.DBName, conf.DBUser, conf.DBPass)
	if err != nil {
		log.Fatal("OpenDB failed: ", err)
	}
	defer CloseDB(db)
	CreateTablesIfNotExists(db)

	updaterHandler := &UpdaterHandler{db: db, conf: &conf}
	http.HandleFunc("/hello", HelloServer)
	http.HandleFunc("/updatecheck", updaterHandler.UpdateCheck)
	http.HandleFunc("/update", updaterHandler.Update)
	http.HandleFunc("/report", updaterHandler.Report)

	port := fmt.Sprintf(":%d", conf.ListenPort)
	if conf.UseTLS {
		err = http.ListenAndServeTLS(port, conf.CertPath, conf.KeyPath, nil)
	} else {
		err = http.ListenAndServe(port, nil)
	}
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}

}
