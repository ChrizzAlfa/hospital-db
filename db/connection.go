package db

import (
    "database/sql"

    _ "github.com/go-sql-driver/mysql"
)

func ConnectDB() (*sql.DB, error) {
    db, err := sql.Open("mysql", "siloam:sehat@tcp(localhost:3306)/hospital")
    if err != nil {
        return nil, err
    }

    return db, nil
}