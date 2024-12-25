package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"

	"github.com/gorilla/mux"
)

func CreateCheckup(w http.ResponseWriter, r *http.Request) {
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

    checkupDate, ok := data["checkup_date"].(string)
    if !ok {
        http.Error(w, "Missing required field: checkup_date", http.StatusBadRequest)
        return
    }

    checkupType, ok := data["checkup_type"].(string)
    if !ok {
        http.Error(w, "Missing required field: checkup_type", http.StatusBadRequest)
        return
    }

    // Run the call sp_AddAppointment query
    _, err = db.Exec(
        "CALL 	sp_InsertCheckup(?, ?, ?, ?, ?);",
        recordID,
        checkupDate,
        checkupType,
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

func UpdateCheckup(w http.ResponseWriter, r *http.Request)  {
	params := mux.Vars(r)
    id := params["id"]

	// Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()
	
    var checkup models.Checkup
    err = json.NewDecoder(r.Body).Decode(&checkup)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    _, err = db.Exec(
		"CALL sp_UpdateCheckup(?, ?)",
		id,
		checkup.Result,
	)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(checkup)
}