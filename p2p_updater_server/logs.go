package main

import (
	"log"
	"sync"
)

type RotateLogger struct {
	logger    *log.Logger
	last_date string
	mutex1    sync.Mutex
	mutex2    sync.Mutex
}

func (logger *RotateLogger) Prepare() {
	day_changed := false
	// TODO: 오늘 날짜를 구한다.
	//       lock1
	//       last_date 와 비교한다.
	//       file 새로 생성
	//       last_date 변경
	//       unlock1

	//       lock2
	//       logger 새로 생성
	//       unlock2
}

func (logger *RotateLogger) Debug(msg string) {
}

func (logger *RotateLogger) Info(msg string) {
	logger.Prepare()
}

func (logger *RotateLogger) Warn(msg string) {
	logger.Prepare()
}

func (logger *RotateLogger) Error(msg string) {
	logger.Prepare()
}

func (logger *RotateLogger) Fatal(msg string) {
}
