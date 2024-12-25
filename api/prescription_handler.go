package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
)

func CreatePrescription(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    var data map[string]interface{}
    err = json.NewDecoder(r.Body).Decode(&data)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    var recordID *int64
    if val, ok := data["record_id"]; ok {
        recordID = new(int64)
        *recordID = int64(val.(float64))
    }

    medication, ok := data["medication"].(string)
    if !ok {
        http.Error(w, "Missing required field: medication", http.StatusBadRequest)
        return
    }

    var patientID *int64
    if val, ok := data["patient_id"]; ok {
        patientID = new(int64)
        *patientID = int64(val.(float64))
    }

    var doctorID *int64
    if val, ok := data["doctor_id"]; ok {
        doctorID = new(int64)
        *doctorID = int64(val.(float64))
    }

    // Run the call sp_CreatePrescription query
    _, err = db.Exec(
        "CALL sp_InsertPrescription(?, ?, ?, ?);",
        recordID,
        medication,
        patientID,
        doctorID,
    )
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Return a success response
    w.WriteHeader(http.StatusCreated)
}