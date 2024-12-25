package api

import (
	"encoding/json"
	"net/http"

	"hospital/db"
	"hospital/models"
)

func ListAvailableRooms(w http.ResponseWriter, r *http.Request) {
    // Connect to the database
    db, err := db.ConnectDB()
    if err != nil {
        http.Error(w, "Failed to connect to database", http.StatusInternalServerError)
        return
    }
    defer db.Close()

    // Execute the stored procedure
    rows, err := db.Query("CALL sp_ListAvailableRooms()")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // Fetch the results
    var availableRooms []models.Room
    for rows.Next() {
        var room models.Room
        err := rows.Scan(&room.RoomID)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        availableRooms = append(availableRooms, room)
    }

    // Return the results as JSON
    json.NewEncoder(w).Encode(availableRooms)
}