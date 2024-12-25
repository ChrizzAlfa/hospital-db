package models

type Checkup struct {
	CheckupID		uint   `json:"checkupid"`
	CheckupDate 	string `json:"checkup_date"`
	CheckupType 	string `json:"checkup_type"`
	Status     		string `json:"status"`
	Result     		string `json:"result"`
}