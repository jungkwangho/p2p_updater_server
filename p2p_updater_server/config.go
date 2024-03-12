package main

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

type Config struct {
	ListenPort int    `json:"listen_port"`
	ServerBase string `json:"server_base"`
	FilesBase  string `json:"files_base"`
	UseTLS     bool   `json:"use_tls"`
	CertPath   string `json:"cert_path"`
	KeyPath    string `json:"key_path"`
	DBAddr     string `json:"db_addr"`
	DBPort     int    `json:"db_port"`
	DBName     string `json:"db_name"`
	DBUser     string `json:"db_user"`
	DBPass     string `json:"db_pass"`
	LogDir     string `json:"log_dir"`
	LogPrefix  string `json:"log_prefix"`
	LogSuffix  string `json:"log_suffix"`
}

func (config *Config) Load(path string) error {

	jsonConfig, err := os.Open(path)
	if err != nil {
		return err
	}
	defer jsonConfig.Close()

	jsonConfigBytes, err := ioutil.ReadAll(jsonConfig)
	if err != nil {
		return err
	}
	json.Unmarshal(jsonConfigBytes, config)
	return nil
}

func (config *Config) Save(path string) error {

	jsonConfigBytes, err := json.Marshal(config)
	if err != nil {
		return err
	}

	ioutil.WriteFile(path, jsonConfigBytes, os.FileMode(644))
	return nil
}
