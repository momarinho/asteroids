package main

import (
	"time"
)

type Player struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"not null" json:"username"`
	CreatedAt time.Time `json:"created_at"`
}

type Score struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	PlayerID  string    `gorm:"not null;index" json:"player_id"`
	Player    Player    `gorm:"foreignKey:PlayerID" json:"player,omitempty"`
	Score     int       `gorm:"not null" json:"score"`
	Level     int       `gorm:"not null" json:"level"`
	Mode      string    `gorm:"not null" json:"mode"`
	CreatedAt time.Time `json:"created_at"`
}
