package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"

	"github.com/gorilla/mux"
)

func CreateAppointment(w http.ResponseWriter, r *http.Request) {
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

    patientEmail, ok := data["email"].(string)
    if !ok {
        http.Error(w, "Missing required field: email", http.StatusBadRequest)
        return
    }

    doctorID, ok := data["doctor_id"].(float64)
    if !ok {
        http.Error(w, "Missing required field: doctor_id", http.StatusBadRequest)
        return
    }

    appointmentDate, ok := data["appointment_date"].(string)
    if !ok {
        http.Error(w, "Missing required field: appointment_date", http.StatusBadRequest)
        return
    }

    appointmentStartTime, ok := data["appointment_start_time"].(string)
    if !ok {
        http.Error(w, "Missing required field: appointment_start_time", http.StatusBadRequest)
        return
    }

    // Run the call sp_AddAppointment query
    _, err = db.Exec(
        "CALL sp_ScheduleAppointment(?, ?, ?, ?);",
        patientEmail,
        int64(doctorID),
        appointmentDate,
        appointmentStartTime,
    )
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Return a success response
    w.WriteHeader(http.StatusCreated)
}

func ListDoctorAppointments(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    params := mux.Vars(r)
    id := params["id"]
    
    var appointments []models.Appointment
    
    query := "CALL sp_GetDoctorAppointments(?);"

    rows, err := db.Query(query, id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var appointment models.Appointment
        err = rows.Scan(&appointment.AppointmentDate, &appointment.AppointmentStartTime, &appointment.AppointmentEndTime)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        appointments = append(appointments, appointment)
    }

    json.NewEncoder(w).Encode(appointments)
}