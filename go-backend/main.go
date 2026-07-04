package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Shared secret key for anti-cheat verification
const SecretKey = "asteroids-secret-token-key-2026"

var db *gorm.DB

func main() {
	var err error
	// Initialize database using pure-go SQLite driver
	db, err = gorm.Open(sqlite.Open("asteroids.db"), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect database: %v", err)
	}

	// Auto-migrate models
	err = db.AutoMigrate(&Player{}, &Score{})
	if err != nil {
		log.Fatalf("Failed to auto-migrate: %v", err)
	}

	// Initialize Gin router
	r := gin.Default()

	// CORS Middleware
	r.Use(CORSMiddleware())

	// Routes
	r.GET("/health", handleHealth)
	r.POST("/players", handleRegisterPlayer)
	r.POST("/scores", handleSubmitScore)
	r.GET("/scores", handleGetScores)

	fmt.Println("Asteroids backend listening on port 8080...")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}

func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, X-Signature")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(244)
			return
		}

		c.Next()
	}
}

func handleHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "healthy"})
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=2,max=20"`
}

func handleRegisterPlayer(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request parameters (username must be 2-20 characters)"})
		return
	}

	// Create new player with UUID
	player := Player{
		ID:       uuid.New().String(),
		Username: req.Username,
	}

	if err := db.Create(&player).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create player profile"})
		return
	}

	c.JSON(http.StatusCreated, player)
}

type SubmitScoreRequest struct {
	PlayerID  string `json:"player_id" binding:"required"`
	Score     int    `json:"score" binding:"required,min=0"`
	Level     int    `json:"level" binding:"required,min=1"`
	Mode      string `json:"mode" binding:"required"`
	Signature string `json:"signature" binding:"required"`
}

func handleSubmitScore(c *gin.Context) {
	var req SubmitScoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 1. Verify player exists
	var player Player
	if err := db.First(&player, "id = ?", req.PlayerID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Player profile not found"})
		return
	}

	// 2. Anti-cheat signature validation
	// HMAC-SHA256 signature of: "player_id:score:level:mode"
	payload := fmt.Sprintf("%s:%d:%d:%s", req.PlayerID, req.Score, req.Level, req.Mode)
	h := hmac.New(sha256.New, []byte(SecretKey))
	h.Write([]byte(payload))
	expectedSignature := hex.EncodeToString(h.Sum(nil))

	if req.Signature != expectedSignature {
		c.JSON(http.StatusForbidden, gin.H{"error": "Score submission rejected: integrity signature mismatch (anti-cheat)"})
		return
	}

	// 3. Save score to database
	scoreRecord := Score{
		PlayerID: req.PlayerID,
		Score:    req.Score,
		Level:    req.Level,
		Mode:     req.Mode,
	}

	if err := db.Create(&scoreRecord).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save score records"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Score submitted successfully!",
		"score":   scoreRecord.Score,
	})
}

func handleGetScores(c *gin.Context) {
	mode := c.DefaultQuery("mode", "classic")
	limitStr := c.DefaultQuery("limit", "10")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 || limit > 100 {
		limit = 10
	}

	var scores []Score
	// Query top scores preloading the player username
	err = db.Preload("Player").
		Where("mode = ?", mode).
		Order("score desc").
		Limit(limit).
		Find(&scores).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve highscores"})
		return
	}

	// Format results for client consumption
	type LeaderboardEntry struct {
		Username  string `json:"username"`
		Score     int    `json:"score"`
		Level     int    `json:"level"`
		CreatedAt string `json:"created_at"`
	}

	results := make([]LeaderboardEntry, len(scores))
	for i, s := range scores {
		results[i] = LeaderboardEntry{
			Username:  s.Player.Username,
			Score:     s.Score,
			Level:     s.Level,
			CreatedAt: s.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	c.JSON(http.StatusOK, results)
}
