package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"
)

func ListDoctors(w http.ResponseWriter, r *http.Request) {
	// Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    var doctors []models.Doctor
	
	// Prepare the SQL query
    query := "CALL sp_ListDoctors();"

    rows, err := db.Query(query)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var doctor models.Doctor
        if err := rows.Scan(&doctor.DoctorID, &doctor.Name, &doctor.Specialization); err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        doctors = append(doctors, doctor)
    }
    json.NewEncoder(w).Encode(doctors)
}