package models

type Doctor struct {
	DoctorID		uint   `json:"doctor_id"`
	Name           	string `json:"name"`
	Specialization 	string `json:"specialization"`
}