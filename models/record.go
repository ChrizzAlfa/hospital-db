package models

type Record struct {
    RecordID      	int       	`json:"record_id"`
    CheckupID     	int       	`json:"checkup_id"`
    PrescriptionID 	int      	`json:"prescription_id"`
    PatientID     	int       	`json:"patient_id"`
    DoctorID      	int       	`json:"doctor_id"`
    CreatedAt     	string 		`json:"created_at"`
    UpdatedAt     	string		`json:"updated_at"`
}