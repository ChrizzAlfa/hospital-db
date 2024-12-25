package models

type Patient struct {
	PatientID int    `json:"patient_id"`
	RoomID    *int   `json:"room_id"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	Gender    string `json:"gender"`
	Status    string `json:"status"`
	Birthday  string `json:"birthday"`
}
