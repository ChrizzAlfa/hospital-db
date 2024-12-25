package models

type Appointment struct {
	AppointmentID          int    `json:"appointment_id"`
	PatientID              int    `json:"patient_id"`
	DoctorID               int    `json:"doctor_id"`
	AppointmentDate        string `json:"appointment_date"`
	AppointmentStartTime   string `json:"appointment_start_time"`
	AppointmentEndTime     string `json:"appointment_end_time,omitempty"`
}