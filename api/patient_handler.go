package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"
)

func CreatePatient(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    // Decode the request body into a ModelPatient struct
    var patient models.Patient
    err = json.NewDecoder(r.Body).Decode(&patient)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    // Prepare the SQL query
    query := "CALL sp_InsertPatient(?, ?, ?, ?)"

    // Execute the SQL query
    _, err = db.Exec(query, patient.Name, patient.Email, patient.Gender, patient.Birthday)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Encode the user into JSON and write it to the response
    json.NewEncoder(w).Encode(patient)
}

func ListPatients(w http.ResponseWriter, r *http.Request)  {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    var patients []models.Patient

    // Prepare the SQL query
    query := "CALL sp_ListAllPatients();"

    rows, err := db.Query(query)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var patient models.Patient
        if err := rows.Scan(&patient.PatientID); err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
    patients = append(patients, patient)
    }
    json.NewEncoder(w).Encode(patients)
}

func AdmitPatient(w http.ResponseWriter, r *http.Request) {
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

    roomID, ok := data["room_id"].(float64)
    if !ok {
        http.Error(w, "Missing required field: room_id", http.StatusBadRequest)
        return
    }

    patientID, ok := data["patient_id"].(float64)
    if !ok {
        http.Error(w, "Missing required field: patient_id", http.StatusBadRequest)
        return
    }

    // Prepare the SQL query
    query := "CALL sp_AdmitPatient(?, ?)"

    // Execute the SQL query
    _, err = db.Exec(query, int(patientID), int(roomID))
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Return a success message
    json.NewEncoder(w).Encode(map[string]string{"message": "Patient admitted successfully"})
}

func DischargePatient(w http.ResponseWriter, r *http.Request) {
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

    patientID, ok := data["patient_id"].(float64)
    if !ok {
        http.Error(w, "Missing required field: patient_id", http.StatusBadRequest)
        return
    }

    // Prepare the SQL query
    query := "CALL sp_DischargePatient(?)"

    // Execute the SQL query
    _, err = db.Exec(query, int(patientID))
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Return a success message
    json.NewEncoder(w).Encode(map[string]string{"message": "Patient discharged successfully"})
}

func ListAdmittedPatients(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    // Execute the stored procedure
    rows, err := db.Query("CALL sp_ListAdmittedPatients()")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // Fetch the results
    var patients []models.Patient
    for rows.Next() {
        var patient models.Patient
        var room models.Room
        err := rows.Scan(&patient.PatientID, &room.RoomID)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        patients = append(patients, patient)
    }

    // Return the results as JSON
    json.NewEncoder(w).Encode(patients)
}