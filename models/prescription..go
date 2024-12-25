package models

type Prescription struct {
    PrescriptionID int 		`json:"prescription_id"`
    Medication     string 	`json:"medication"`
}