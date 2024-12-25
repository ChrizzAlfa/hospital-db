package main

import (
	"hospital/api"
	"log"
	"net/http"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

func main() {
    // Initialize router
    router := mux.NewRouter()

    // Define API routes
    router.HandleFunc("/api/patients", api.CreatePatient).Methods("POST")
    router.HandleFunc("/api/doctors", api.ListDoctors).Methods("GET")
    router.HandleFunc("/api/doctors/{id}/appointments", api.ListDoctorAppointments).Methods("GET")
    router.HandleFunc("/api/appointments", api.CreateAppointment).Methods("POST")
    router.HandleFunc("/api/records", api.ListRecords).Methods("GET")
    router.HandleFunc("/api/prescriptions", api.CreatePrescription).Methods("POST")
    router.HandleFunc("/api/checkups", api.CreateCheckup).Methods("POST")
    router.HandleFunc("/api/checkups/{id}", api.UpdateCheckup).Methods("PUT")
    router.HandleFunc("/api/patients", api.ListPatients).Methods("GET")
    router.HandleFunc("/api/rooms/available", api.ListAvailableRooms).Methods("GET")
    router.HandleFunc("/api/patients/admit", api.AdmitPatient).Methods("POST")
    router.HandleFunc("/api/patients/admitted", api.ListAdmittedPatients).Methods("GET")
    router.HandleFunc("/api/patients/{id}/discharge", api.DischargePatient).Methods("POST")
    

    // Start server on port 8000
    log.Fatal(http.ListenAndServe(":8000", router))
}