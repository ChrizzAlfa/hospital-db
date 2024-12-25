package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"
)

func ListRecords(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    // Execute the stored procedure
    rows, err := db.Query("CALL sp_ListRecords()")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // Fetch the results
    var records []models.Record
    for rows.Next() {
        var record models.Record
        err := rows.Scan(&record.RecordID, &record.CheckupID, &record.PrescriptionID, &record.PatientID, &record.DoctorID)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        records = append(records, record)
    }

    // Return the results as JSON
    json.NewEncoder(w).Encode(records)
}