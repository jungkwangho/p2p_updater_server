package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type RotateLogger struct {
	_logger    *log.Logger
	_logfile   *os.File
	_conf      *Config
	_last_date string
	_mutex     sync.Mutex
}

func (logger *RotateLogger) Init(conf *Config) {
	logger._logger = nil
	logger._logfile = nil
	logger._conf = conf
	logger._last_date = ""

	time.LoadLocation("Asia/Seoul")
}

func (logger *RotateLogger) Close() {
	if logger._logfile != nil {
		logger._logfile.Close()
	}
}

func (logger *RotateLogger) RLog() *log.Logger {

	now := time.Now()
	today := fmt.Sprintf("%d_%d_%d", now.Year(), now.Month(), now.Day())

	logger._mutex.Lock()
	defer logger._mutex.Unlock()

	if today != logger._last_date {
		log_dir := logger._conf.LogDir
		if _, err := os.Stat(log_dir); os.IsNotExist(err) {
			os.MkdirAll(log_dir, os.ModePerm)
		}
		log_path := filepath.Join(log_dir, logger._conf.LogPrefix+today+logger._conf.LogSuffix)
		oldfile := logger._logfile
		logfile, err := os.OpenFile(log_path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err == nil {
			logger._last_date = today
			logger._logfile = logfile
			log.SetOutput(logger._logfile)
			logger._logger = log.New(logger._logfile, "", log.Ldate|log.Ltime|log.Lshortfile)
			if oldfile != nil {
				defer oldfile.Close()
			}
		} else {
			fmt.Println(err)
			if logfile != nil {
				logfile.Close()
			}
		}
	}

	return logger._logger
}
