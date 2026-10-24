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
	r.GET("/live", handleLiveLeaderboard)
	r.GET("/ranking", handleLiveLeaderboard)

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
	Scientist string `json:"scientist"`
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
		PlayerID:  req.PlayerID,
		Scientist: req.Scientist,
		Score:     req.Score,
		Level:     req.Level,
		Mode:      req.Mode,
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
		Scientist string `json:"scientist"`
		Score     int    `json:"score"`
		Level     int    `json:"level"`
		CreatedAt string `json:"created_at"`
	}

	results := make([]LeaderboardEntry, len(scores))
	for i, s := range scores {
		scientist := s.Scientist
		if scientist == "" {
			scientist = "Pioneira"
		}
		results[i] = LeaderboardEntry{
			Username:  s.Player.Username,
			Scientist: scientist,
			Score:     s.Score,
			Level:     s.Level,
			CreatedAt: s.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	c.JSON(http.StatusOK, results)
}

func handleLiveLeaderboard(c *gin.Context) {
	var scores []Score
	db.Preload("Player").
		Where("mode = ?", "arcade").
		Order("score desc").
		Limit(15).
		Find(&scores)

	html := `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="3">
<title>Ranking ao Vivo • Mulheres na Ciência</title>
<style>
  body { background: #0a0e17; color: #fff; font-family: 'Courier New', monospace; margin: 0; padding: 24px; display: flex; flex-direction: column; align-items: center; }
  h1 { color: #00e5ff; letter-spacing: 3px; margin-bottom: 4px; text-shadow: 0 0 12px #00e5ff88; }
  p.subtitle { color: #8892b0; margin-top: 0; font-size: 14px; letter-spacing: 1.5px; }
  table { width: 90%; max-width: 800px; border-collapse: collapse; margin-top: 20px; background: rgba(255,255,255,0.03); border: 1px solid rgba(0,229,255,0.3); border-radius: 12px; overflow: hidden; }
  th { background: rgba(0,229,255,0.15); color: #00e5ff; padding: 14px; text-align: left; font-size: 14px; letter-spacing: 1.5px; }
  td { padding: 12px 14px; border-bottom: 1px solid rgba(255,255,255,0.06); font-size: 15px; }
  tr:nth-child(1) td { color: #ffd700; font-weight: bold; font-size: 17px; }
  tr:nth-child(2) td { color: #cfd8dc; font-weight: bold; }
  tr:nth-child(3) td { color: #bcaaa4; font-weight: bold; }
  .badge { background: rgba(0,230,118,0.2); color: #00e676; padding: 4px 8px; border-radius: 6px; font-size: 12px; border: 1px solid rgba(0,230,118,0.4); }
  .refresh-hint { margin-top: 16px; color: #556; font-size: 12px; }
</style>
</head>
<body>
  <h1>RANKING DA FEIRA DE CIÊNCIAS</h1>
  <p class="subtitle">MULHERES NA CIÊNCIA • TOP PILOTOS ESPACIAIS</p>
  <table>
    <thead>
      <tr><th>POS</th><th>PILOTO</th><th>CIENTISTA</th><th style="text-align:right">PONTOS</th></tr>
    </thead>
    <tbody>`

	if len(scores) == 0 {
		html += `<tr><td colspan="4" style="text-align:center; padding: 24px; color: #667;">Nenhum recorde registrado ainda. Seja a primeira a jogar!</td></tr>`
	} else {
		for i, s := range scores {
			pos := fmt.Sprintf("#%d", i+1)
			scientist := s.Scientist
			if scientist == "" {
				scientist = "Pioneira"
			}
			html += fmt.Sprintf(`<tr>
				<td>%s</td>
				<td><strong>%s</strong></td>
				<td><span class="badge">%s</span></td>
				<td style="text-align:right; font-weight:bold;">%d</td>
			</tr>`, pos, s.Player.Username, scientist, s.Score)
		}
	}

	html += `</tbody></table>
  <p class="refresh-hint">Atualização automática em tempo real a cada 3 segundos • Asteroids</p>
</body>
</html>`

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
}
