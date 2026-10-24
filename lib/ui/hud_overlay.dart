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
    final scientist = game.selectedScientist;

    final livesLeft = game.lives;
    final score = game.score;
    final timeRemaining = game.timeRemaining;

    final isInvulnerable = player.isInvulnerable();
    final invulTime = player.invulnerableTimer;
    final shootCooldown = player.shootTimer;
    final dashCooldown = player.dashCooldownTimer;
    final currentWeapon = player.weapon;

    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Stack(
        children: [
          // Top Left: Score, Scientist Badge & Ship Name
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PONTOS: $score',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.cyan, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scientist.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: scientist.primaryColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, color: scientist.primaryColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          scientist.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scientist.primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NAVE: ${scientist.shipName}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      color: scientist.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Center: Mission Timer Countdown
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: timeRemaining < 30 ? Colors.redAccent : scientist.primaryColor.withOpacity(0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (timeRemaining < 30 ? Colors.red : scientist.primaryColor).withOpacity(0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: timeRemaining < 30 ? Colors.redAccent : scientist.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(timeRemaining.toInt() % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: timeRemaining < 30 ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Right: 3 Lives & Shield Indicator
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index < livesLeft;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          Icons.favorite,
                          color: isActive ? scientist.primaryColor : Colors.white24,
                          size: 22,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (isInvulnerable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Text(
                        'ESCUDO: ${invulTime.toStringAsFixed(1)}s',
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
          ),

          // Bottom Left: Weapon Stats and Dash Cooldown (Ignore Pointer so click-through works)
          Positioned(
            bottom: 0,
            left: 0,
            child: IgnorePointer(
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
        ),

          // Bottom Right: Mobile touch action buttons (Shoot & Dash)
          if (game.isMobile)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Dash Button (smaller, blue/cyan glowing icon button)
                  GestureDetector(
                    onTapDown: (_) {
                      game.mobileDashPressed = true;
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: player.dashCooldownTimer <= 0
                              ? Colors.cyanAccent
                              : Colors.white24,
                          width: 2,
                        ),
                        boxShadow: player.dashCooldownTimer <= 0
                            ? [
                                BoxShadow(
                                  color: Colors.cyan.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.bolt,
                        color: player.dashCooldownTimer <= 0
                            ? Colors.cyanAccent
                            : Colors.white24,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Shoot Button (larger, red/orange glowing icon button)
                  GestureDetector(
                    onTapDown: (_) {
                      game.mobileShootPressed = true;
                    },
                    onTapUp: (_) {
                      game.mobileShootPressed = false;
                    },
                    onTapCancel: () {
                      game.mobileShootPressed = false;
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.gps_fixed,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
