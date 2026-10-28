import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';

class HudOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Placar animado: o número exibido "corre" até a pontuação real
  double _displayScore = 0.0;
  int _lastScore = 0;
  double _scorePulse = 0.0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lastScore = widget.game.score;
    _displayScore = widget.game.score.toDouble();
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.1);
      _lastElapsed = elapsed;
      _tickScore(dt);
      if (mounted) {
        setState(() {});
      }
    });
    _ticker.start();
  }

  void _tickScore(double dt) {
    final target = widget.game.score;
    if (target < _lastScore) {
      // Nova partida: reinicia sem animar
      _displayScore = target.toDouble();
      _scorePulse = 0.0;
    } else if (target > _lastScore) {
      _scorePulse = 1.0;
    }
    _lastScore = target;

    final diff = target - _displayScore;
    if (diff.abs() < 1.0) {
      _displayScore = target.toDouble();
    } else {
      _displayScore += diff * math.min(1.0, dt * 7.0);
    }
    _scorePulse = math.max(0.0, _scorePulse - dt * 3.5);
  }

  /// Formata com separador de milhar no padrão brasileiro (12.450).
  String _formatScore(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  /// Cor do cronômetro: tema da cientista → âmbar → vermelho, de forma gradual.
  Color _timeColor(double t, Color primary) {
    if (t >= 90) return primary;
    if (t >= 60) return Color.lerp(Colors.amberAccent, primary, (t - 60) / 30)!;
    if (t >= 35) return Colors.amberAccent;
    if (t >= 25) return Color.lerp(Colors.redAccent, Colors.amberAccent, (t - 25) / 10)!;
    return Colors.redAccent;
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'PONTOS',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 1.0 + 0.14 * _scorePulse,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          _formatScore(_displayScore.round()),
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontVariations: const [FontVariation('wght', 800)],
                            fontSize: 26,
                            color: Color.lerp(Colors.white, scientist.accentColor, _scorePulse * 0.8),
                            shadows: [
                              Shadow(
                                color: Color.lerp(Colors.cyan, scientist.primaryColor, _scorePulse)!
                                    .withOpacity(0.7 + _scorePulse * 0.3),
                                blurRadius: 8 + _scorePulse * 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                            fontFamily: 'Rajdhani',
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
                      fontFamily: 'Rajdhani',
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
                            fontFamily: 'Rajdhani',
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
                              fontFamily: 'Rajdhani',
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

                    Builder(
                      builder: (context) {
                        final timeColor = _timeColor(timeRemaining, scientist.primaryColor);
                        // Pulso do brilho nos últimos 30s para aumentar a tensão
                        final urgency = timeRemaining <= 30
                            ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                            : 0.0;
                        final progress = (timeRemaining / AsteroidsGame.fairRoundDuration).clamp(0.0, 1.0);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: timeColor.withOpacity(0.85),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: timeColor.withOpacity(0.25 + urgency * 0.35),
                                    blurRadius: 12 + urgency * 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, color: timeColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(timeRemaining.toInt() % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontVariations: const [FontVariation('wght', 800)],
                                      fontSize: 20,
                                      letterSpacing: 2,
                                      color: Color.lerp(Colors.white, timeColor, timeRemaining <= 60 ? 1.0 : 0.0),
                                      shadows: [
                                        Shadow(color: timeColor.withOpacity(0.7), blurRadius: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Barra de progresso do tempo restante
                            Container(
                              width: 150,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: LinearGradient(
                                        colors: [timeColor.withOpacity(0.55), timeColor],
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: timeColor.withOpacity(0.55), blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
                                fontFamily: 'Rajdhani',
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
                    if (timeRemaining <= 30) ...[
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
                                fontFamily: 'Rajdhani',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (timeRemaining <= 60) ...[
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
                                fontFamily: 'Rajdhani',
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
                    if (game.cometAlertTimer > 0 && game.cometAlertMessage != null) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 140) + 1) / 2;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withOpacity(0.6 + pulse * 0.4),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.35 + pulse * 0.45),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  game.cometAlertMessage!,
                                  style: const TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                    shadows: [
                                      Shadow(color: Color(0xFF00E5FF), blurRadius: 6),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                                fontFamily: 'Rajdhani',
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
                        fontFamily: 'Rajdhani',
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
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
                                fontFamily: 'Orbitron',
                                fontVariations: [FontVariation('wght', 700)],
                                fontSize: 12,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'NÍVEL ${currentWeapon.level}',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scientist.accentColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Cooldown bar
                            Row(
                              children: [
                                const Text(
                                  'CD ',
                                  style: TextStyle(fontFamily: 'Rajdhani', fontSize: 8, color: Colors.white54),
                                ),
                                Container(
                                  width: 76,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: shootCooldown <= 0
                                          ? 76
                                          : (76 * (1 - (shootCooldown / currentWeapon.cooldown))).clamp(0.0, 76.0),
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: shootCooldown <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (shootCooldown <= 0 ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Dash Status with Radial Progress Ring
                      Builder(
                        builder: (context) {
                          final isReady = dashCooldown <= 0;
                          final progress = isReady
                              ? 1.0
                              : (1.0 - (dashCooldown / GameConstants.playerDashCooldownSeconds)).clamp(0.0, 1.0);
                          final dashPulse = isReady
                              ? (math.sin(DateTime.now().millisecondsSinceEpoch / 250) + 1) / 2
                              : 0.0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isReady
                                    ? Colors.cyanAccent.withOpacity(0.55 + dashPulse * 0.35)
                                    : Colors.white24,
                                width: isReady ? 1.4 : 1.0,
                              ),
                              boxShadow: isReady
                                  ? [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(0.25 + dashPulse * 0.25),
                                        blurRadius: 8 + dashPulse * 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 2.5,
                                        backgroundColor: Colors.white12,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isReady ? Colors.cyanAccent : Colors.cyan.withOpacity(0.5),
                                        ),
                                      ),
                                      Icon(
                                        Icons.bolt,
                                        size: 15,
                                        color: isReady ? Colors.cyanAccent : Colors.white38,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'DASH',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontVariations: const [FontVariation('wght', 700)],
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                        color: isReady ? Colors.cyanAccent : Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isReady ? 'PRONTO' : '${dashCooldown.toStringAsFixed(1)}s',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isReady ? Colors.cyanAccent : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Item 1: Special Ability Card (Clickable or [E])
                GestureDetector(
                  onTap: () {
                    game.triggerSpecial();
                  },
                  child: Builder(
                    builder: (context) {
                      final isReady = game.specialAvailable;
                      final specialPulse = isReady
                          ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                          : 0.0;
                      final glowColor = isReady ? scientist.primaryColor : Colors.white24;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isReady
                              ? scientist.primaryColor.withOpacity(0.16 + specialPulse * 0.10)
                              : Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isReady
                                ? scientist.primaryColor.withOpacity(0.7 + specialPulse * 0.3)
                                : Colors.white24,
                            width: isReady ? 1.6 : 1.0,
                          ),
                          boxShadow: isReady
                              ? [
                                  BoxShadow(
                                    color: scientist.primaryColor.withOpacity(0.35 + specialPulse * 0.35),
                                    blurRadius: 10 + specialPulse * 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isReady
                                    ? scientist.primaryColor.withOpacity(0.25)
                                    : Colors.white10,
                                border: Border.all(
                                  color: glowColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isReady ? Icons.auto_awesome : Icons.check_circle_outline,
                                color: isReady ? const Color(0xFFFFD700) : Colors.white38,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      scientist.specialAbilityName.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: isReady ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                    if (isReady) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.amberAccent, width: 0.8),
                                        ),
                                        child: const Text(
                                          '[E]',
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReady ? '1 CARGA PRONTA' : 'JÁ UTILIZADO',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isReady ? Colors.amberAccent : Colors.white24,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
                    child: Builder(
                      builder: (context) {
                        final isReady = game.specialAvailable;
                        final pulse = isReady
                            ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                            : 0.0;

                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isReady
                                ? scientist.primaryColor.withOpacity(0.22 + pulse * 0.12)
                                : Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isReady
                                  ? scientist.primaryColor.withOpacity(0.8 + pulse * 0.2)
                                  : Colors.white24,
                              width: isReady ? 2.5 : 1.5,
                            ),
                            boxShadow: isReady
                                ? [
                                    BoxShadow(
                                      color: scientist.primaryColor.withOpacity(0.4 + pulse * 0.3),
                                      blurRadius: 10 + pulse * 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isReady ? Icons.auto_awesome : Icons.lock_outline,
                            color: isReady ? const Color(0xFFFFD700) : Colors.white24,
                            size: 26,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Dash Button (with radial cooldown ring)
                  GestureDetector(
                    onTapDown: (_) {
                      game.mobileDashPressed = true;
                    },
                    child: Builder(
                      builder: (context) {
                        final isReady = player.dashCooldownTimer <= 0;
                        final progress = isReady
                            ? 1.0
                            : (1.0 - (player.dashCooldownTimer / GameConstants.playerDashCooldownSeconds)).clamp(0.0, 1.0);
                        final pulse = isReady
                            ? (math.sin(DateTime.now().millisecondsSinceEpoch / 250) + 1) / 2
                            : 0.0;

                        return SizedBox(
                          width: 56,
                          height: 56,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.cyan.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: isReady
                                      ? [
                                          BoxShadow(
                                            color: Colors.cyanAccent.withOpacity(0.35 + pulse * 0.25),
                                            blurRadius: 8 + pulse * 4,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                              SizedBox(
                                width: 54,
                                height: 54,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3.0,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isReady ? Colors.cyanAccent : Colors.cyan.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.bolt,
                                color: isReady ? Colors.cyanAccent : Colors.white30,
                                size: 28,
                              ),
                            ],
                          ),
                        );
                      },
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
                        color: Colors.redAccent.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.35),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
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
                          fontFamily: 'Rajdhani',
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

          // Retro Sci-Fi / RPG Transmission Dialogue Box at Launch
          if (game.showLaunchTransmission)
            Positioned(
              bottom: game.isMobile ? 120 : 35,
              left: 20,
              right: 20,
              child: Center(
                child: GestureDetector(
                  onTap: () => game.dismissLaunchTransmission(),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xF00A0F1D), // Dark cosmic glass
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scientist.primaryColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scientist.primaryColor.withOpacity(0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Scientist Avatar / Radio Portrait
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: scientist.accentColor, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: scientist.primaryColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(scientist.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Dialogue text & metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Comms Frequency & Name Header
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'CANAL ABERTO • ${scientist.name.toUpperCase()} (${scientist.role.toUpperCase()})',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: scientist.accentColor,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Scientist Inspiring Launch Phrase
                              Text(
                                '"${scientist.launchQuote}"',
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Dismiss Prompt
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pressione qualquer botão para continuar ▶',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.65),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
