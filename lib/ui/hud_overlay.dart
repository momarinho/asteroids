import 'dart:math' as math;
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
          // Item 5: Last Life Dramatic Red Pulsing Vignette
          if (livesLeft == 1)
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 220) + 1) / 2;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Colors.red.withOpacity(0.08 + pulse * 0.16),
                            Colors.red.withOpacity(0.24 + pulse * 0.28),
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35 + pulse * 0.45),
                          width: 3.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Top Left: Score, Scientist Badge, Ship Name & Science Samples Badge
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

                  // Item 2: Science Samples Collected Badge
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.biotech, color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AMOSTRAS: ${game.samplesCollected}',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Center: Mission Timer Countdown, Fair Leader Target & Alerts
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item 3: Fair Leader Target Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: game.topRecordBeaten
                            ? const Color(0xFFFFD700).withOpacity(0.25)
                            : Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: game.topRecordBeaten
                              ? const Color(0xFFFFD700)
                              : Colors.amberAccent.withOpacity(0.7),
                          width: 1.2,
                        ),
                        boxShadow: game.topRecordBeaten
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            game.topRecordBeaten ? Icons.emoji_events : Icons.military_tech,
                            color: const Color(0xFFFFD700),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            game.topRecordBeaten
                                ? '👑 NOVO RECORDE DA FEIRA! (#1) 👑'
                                : '🏆 LÍDER: ${(game.topLeaderName != null && game.topLeaderName!.isNotEmpty) ? game.topLeaderName : "RECORDE"} (${game.topLeaderScore} pts)',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: game.topRecordBeaten
                                  ? const Color(0xFFFFD700)
                                  : Colors.amber.shade200,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: timeRemaining <= 25
                              ? Colors.redAccent
                              : (timeRemaining <= 45 ? Colors.amberAccent : scientist.primaryColor.withOpacity(0.7)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (timeRemaining <= 25
                                    ? Colors.red
                                    : (timeRemaining <= 45 ? Colors.amber : scientist.primaryColor))
                                .withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: timeRemaining <= 25
                                ? Colors.redAccent
                                : (timeRemaining <= 45 ? Colors.amberAccent : scientist.primaryColor),
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
                              color: timeRemaining <= 25
                                  ? Colors.redAccent
                                  : (timeRemaining <= 45 ? Colors.amberAccent : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (livesLeft == 1) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.yellowAccent, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 14),
                            SizedBox(width: 5),
                            Text(
                              '⚠️ ALERTA CRÍTICO: ÚLTIMA VIDA! ⚠️',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (timeRemaining <= 25) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'HIPER TEMPESTADE DE METEOROS!',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (timeRemaining <= 45) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amberAccent, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ALERTA: METEOROS SE APROXIMANDO!',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amberAccent,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Top Right: 3 Lives, Shield Indicator & Pause Button
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3 Lives
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
                    const SizedBox(width: 14),

                    // Pause Button
                    GestureDetector(
                      onTap: () {
                        game.togglePause();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'PAUSA',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

          // Bottom Left: Weapon Stats, Dash Cooldown and Emergency Special Card
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IgnorePointer(
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
                const SizedBox(width: 15),

                // Item 1: Special Ability Card (Clickable or [E])
                GestureDetector(
                  onTap: () {
                    game.triggerSpecial();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: game.specialAvailable
                          ? scientist.primaryColor.withOpacity(0.18)
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: game.specialAvailable
                            ? scientist.primaryColor
                            : Colors.white24,
                        width: game.specialAvailable ? 1.5 : 1.0,
                      ),
                      boxShadow: game.specialAvailable
                          ? [
                              BoxShadow(
                                color: scientist.primaryColor.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              game.specialAvailable ? Icons.auto_awesome : Icons.check_circle_outline,
                              color: game.specialAvailable ? scientist.primaryColor : Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'ESPECIAL [E]',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: game.specialAvailable ? scientist.primaryColor : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.specialAvailable ? '1 USO DISPONÍVEL' : 'JÁ UTILIZADO',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: game.specialAvailable ? Colors.amberAccent : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Right: Mobile touch action buttons (Special, Dash, Shoot)
          if (game.isMobile)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Item 1: Mobile Special Ability Button (1-use emergency)
                  GestureDetector(
                    onTap: () {
                      game.triggerSpecial();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: game.specialAvailable
                            ? scientist.primaryColor.withOpacity(0.2)
                            : Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: game.specialAvailable
                              ? scientist.primaryColor
                              : Colors.white24,
                          width: 2,
                        ),
                        boxShadow: game.specialAvailable
                            ? [
                                BoxShadow(
                                  color: scientist.primaryColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        game.specialAvailable ? Icons.auto_awesome : Icons.lock_outline,
                        color: game.specialAvailable
                            ? scientist.primaryColor
                            : Colors.white24,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

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

          // Desktop/PC Keyboard Controls Guide
          if (!game.isMobile)
            Positioned(
              bottom: 15,
              right: 15,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard, color: Colors.white54, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'W/▲: ACELERAR  •  A/D: GIRAR  •  ESPAÇO: ATIRAR  •  SHIFT: DASH  •  E: ESPECIAL  •  ESC/P: PAUSA',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
