import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:asteroids/game/asteroids_game.dart';

class HudOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final player = game.player;

    final livesLeft = game.lives;
    final score = game.score;
    final credits = game.credits;
    final currentLevel = game.currentLevel;
    final activeMode = game.activeMode;

    final isInvulnerable = player.isInvulnerable();
    final invulTime = player.invulnerableTimer;
    final shootCooldown = player.shootTimer;
    final dashCooldown = player.dashCooldownTimer;
    final currentWeapon = player.weapon;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
          // Top Left: Score, Mode, Level
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.cyan, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  activeMode == 'campaign' ? 'STAGE: $currentLevel' : 'MODE: CLASSIC',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.cyanAccent,
                  ),
                ),
                if (activeMode == 'campaign') ...[
                  const SizedBox(height: 5),
                  Text(
                    'CREDITS: ${credits}C',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
                if (activeMode == 'classic' && game.asteroidField != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'DANGER: ${game.asteroidField!.dangerLevel().toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: game.asteroidField!.dangerLevel() == 'High'
                          ? Colors.redAccent
                          : (game.asteroidField!.dangerLevel() == 'Medium' ? Colors.orangeAccent : Colors.greenAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Top Right: Lives and Invulnerability Status
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Lives Indicator (Ship icons)
                Row(
                  children: List.generate(5, (index) {
                    final isActive = index < livesLeft;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.navigation,
                        color: isActive ? Colors.white : Colors.white24,
                        size: 20,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                if (isInvulnerable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Text(
                      'SHIELD: ${invulTime.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Left: Weapon Stats and Dash Cooldown
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Active Weapon Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentWeapon.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LEVEL ${currentWeapon.level}',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Cooldown bar
                      Row(
                        children: [
                          const Text(
                            'CD ',
                            style: TextStyle(fontFamily: 'Courier', fontSize: 8, color: Colors.white54),
                          ),
                          Container(
                            width: 80,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: shootCooldown <= 0
                                    ? 80
                                    : (80 * (1 - (shootCooldown / currentWeapon.cooldown))).clamp(0.0, 80.0),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: shootCooldown <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),

                // Dash Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: dashCooldown <= 0 ? Colors.cyan.withOpacity(0.5) : Colors.white24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DASH',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dashCooldown <= 0 ? Colors.cyanAccent : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dashCooldown <= 0 ? 'READY' : '${dashCooldown.toStringAsFixed(1)}s',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: dashCooldown <= 0 ? Colors.cyanAccent : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
