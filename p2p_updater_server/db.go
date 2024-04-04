package main

import (
	"database/sql"
	"errors"
	"fmt"

	_ "github.com/go-sql-driver/mysql"
)

type FileInfo struct {
	Type       string
	Hash       string
	Name       string
	Version    string
	StoredPath sql.NullString
	UpdateId   sql.NullInt64
}

func OpenDB(db_addr string, db_port int, db_name string, db_user string, db_pass string) (*sql.DB, error) {

	connstr := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s", db_user, db_pass, db_addr, db_port, db_name)
	db, err := sql.Open("mysql", connstr)
	if err != nil {
		return nil, err
	}

	db.SetMaxIdleConns(64)

	return db, nil
}

func CreateTablesIfNotExists(db *sql.DB) {

	return

	/*
		tables := []string{
			"create table if not exists files (id int not null auto_increment primary key, type char not null, version varchar(32) not null, hash varchar(64) not null unique key, name varchar(64) not null, stored_path varchar(1024), update_id int, enable bool default(true) not null, register_date datetime default(CURRENT_TIMESTAMP) not null, last_modified datetime default(CURRENT_TIMESTAMP) not null);",
			"create table if not exists reports (id int not null auto_increment primary key, userid varchar(256), ip varchar(64), old_hash varchar(64) not null, new_hash varchar(64) not null, old_name varchar(64) not null, new_name varchar(64) not null, old_version varchar(32) not null, new_version varchar(32) not null, err_code int not null, err_msg varchar(1024), report_date datetime default(CURRENT_TIMESTAMP) not null );",
		}

		for i := 0; i < len(tables); i++ {
			db.Exec(tables[i])
		}
	*/
}

func GetStoredPathByHash(db *sql.DB, hash string) (string, error) {

	var stored_path sql.NullString

	querystr := fmt.Sprintf("select stored_path from catalog_file where hash='%s' and enable=true", hash)
	rows, err := db.Query(querystr)
	if err != nil {
		return "", err
	}
	defer rows.Close()

	for rows.Next() {
		err = rows.Scan(&stored_path)
		if err != nil {
			return "", err
		} else {
			break
		}
	}

	return stored_path.String, nil
}

func GetFileInfoById(db *sql.DB, id int64) (*FileInfo, error) {
	var info FileInfo
	querystr := fmt.Sprintf("select type, version, hash, name, stored_path, update_id from catalog_file where id='%d' and enable=true;", id)
	rows, err := db.Query(querystr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	if rows.Next() {
		err = rows.Scan(&info.Type, &info.Version, &info.Hash, &info.Name, &info.StoredPath, &info.UpdateId)
		if err != nil {
			return nil, err
		}
		fmt.Println(info)
	} else {
		fmt.Println("no corresponding file exists 1")
		return nil, errors.New("no corresponding file exists 1")
	}
	return &info, nil
}

func GetUpdateInfo(db *sql.DB, old_file *FileInfo) (*FileInfo, error) {

	var querystr = ""
	if old_file.Hash != "" {
		querystr = fmt.Sprintf("select update_id from catalog_file where type='%s' and version='%s' and hash='%s' and name='%s' order by register_date desc limit 1;", old_file.Type, old_file.Version, old_file.Hash, old_file.Name)
	} else {
		querystr = fmt.Sprintf("select update_id from catalog_file where type='%s' and version='%s' and name='%s' order by register_date desc limit 1;", old_file.Type, old_file.Version, old_file.Name)
	}

	rows, err := db.Query(querystr)
	if err != nil {
		fmt.Println(err)
		return nil, err
	}
	defer rows.Close()

	var update_info *FileInfo
	var update_id sql.NullInt64
	if rows.Next() {
		err = rows.Scan(&update_id)
		if err != nil {
			fmt.Println(err)
			return nil, err
		}

		if !update_id.Valid {
			fmt.Println("no update exists")
			return nil, errors.New("no update exists")
		}

		fmt.Println(update_id)
		for update_id.Valid {

			update_info, err = GetFileInfoById(db, update_id.Int64)
			if err != nil {
				return nil, err
			}
			update_id = update_info.UpdateId
		}

	} else {
		fmt.Println("no correspoding file exists 2")
		return nil, errors.New("no correspoding file exists 2")
	}
	return update_info, nil
}

func InsertReport(db *sql.DB, old_info, new_info *MinFileInfo, user_id, ip, err_code, err_msg string) error {
	querystmt, err := db.Prepare("insert into catalog_report values (0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);")
	if err != nil {
		return err
	}

	_, err = querystmt.Exec(user_id, ip, old_info.Hash, new_info.Hash, old_info.Name, new_info.Name, old_info.Version, new_info.Version, err_code, err_msg)
	if err != nil {
		return err
	}
	return nil
}

func CloseDB(db *sql.DB) {
	db.Close()
}
