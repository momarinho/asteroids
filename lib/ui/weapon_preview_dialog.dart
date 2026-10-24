import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/scientist.dart';

class WeaponPreviewDialog extends StatefulWidget {
  final Scientist scientist;
  final AsteroidsGame game;

  const WeaponPreviewDialog({
    super.key,
    required this.scientist,
    required this.game,
  });

  static Future<void> show(BuildContext context, Scientist scientist, AsteroidsGame game) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => WeaponPreviewDialog(scientist: scientist, game: game),
    );
  }

  @override
  State<WeaponPreviewDialog> createState() => _WeaponPreviewDialogState();
}

class _WeaponPreviewDialogState extends State<WeaponPreviewDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_SimBullet> _bullets = [];
  final List<_SimSpark> _sparks = [];

  // Dummy Asteroid in simulation
  Offset _asteroidPos = const Offset(140, 45);
  double _asteroidRadius = 20.0;
  double _asteroidHp = 100.0;
  double _asteroidFlashTimer = 0.0;
  double _fireTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateSimulation)..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateSimulation() {
    const dt = 0.016; // ~60fps
    _fireTimer += dt;
    if (_asteroidFlashTimer > 0) {
      _asteroidFlashTimer = math.max(0.0, _asteroidFlashTimer - dt);
    }

    // Weapon-specific auto fire
    final scientist = widget.scientist;
    double fireCooldown;
    switch (scientist.weaponId) {
      case 'rapid_fire':
        fireCooldown = 0.14;
        break;
      case 'spread_shot':
        fireCooldown = 0.48;
        break;
      case 'bomb_launcher':
        fireCooldown = 0.85;
        break;
      case 'blaster':
      default:
        fireCooldown = 0.32;
        break;
    }

    if (_fireTimer >= fireCooldown) {
      _fireTimer = 0.0;
      _spawnSimBullets();
    }

    // Update bullets
    for (int i = _bullets.length - 1; i >= 0; i--) {
      final b = _bullets[i];
      b.pos += b.vel * dt;
      b.life -= dt;

      // Check collision with asteroid
      final dist = (b.pos - _asteroidPos).distance;
      if (dist <= (_asteroidRadius + b.radius)) {
        _asteroidHp -= b.damage;
        _asteroidFlashTimer = 0.12;

        // Spawn sparks
        final sparkCount = b.isBomb ? 18 : 6;
        for (int s = 0; s < sparkCount; s++) {
          final angle = math.Random().nextDouble() * 2 * math.pi;
          final spd = 40.0 + math.Random().nextDouble() * 90.0;
          _sparks.add(_SimSpark(
            pos: b.pos,
            vel: Offset(math.cos(angle) * spd, math.sin(angle) * spd),
            color: b.color,
            life: 0.35 + math.Random().nextDouble() * 0.25,
          ));
        }

        _bullets.removeAt(i);

        // Asteroid shattered
        if (_asteroidHp <= 0) {
          _asteroidHp = 100.0;
          // Reposition dummy asteroid randomly slightly left or right
          _asteroidPos = Offset(110 + math.Random().nextDouble() * 60, 45);
        }
        continue;
      }

      if (b.life <= 0 || b.pos.dy < -10 || b.pos.dx < -10 || b.pos.dx > 300) {
        _bullets.removeAt(i);
      }
    }

    // Update sparks
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.pos += s.vel * dt;
      s.life -= dt;
      if (s.life <= 0) {
        _sparks.removeAt(i);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnSimBullets() {
    const shipMuzzle = Offset(140, 150);
    final scientist = widget.scientist;

    if (scientist.weaponId == 'spread_shot') {
      // 3 fan bullets
      final angles = [-14.0, 0.0, 14.0];
      for (final a in angles) {
        final rad = (a - 90.0) * math.pi / 180.0;
        const spd = 210.0;
        _bullets.add(_SimBullet(
          pos: shipMuzzle,
          vel: Offset(math.cos(rad) * spd, math.sin(rad) * spd),
          color: scientist.primaryColor,
          radius: 3.5,
          damage: 35.0,
          life: 0.9,
        ));
      }
    } else if (scientist.weaponId == 'rapid_fire') {
      _bullets.add(_SimBullet(
        pos: shipMuzzle,
        vel: const Offset(0, -260),
        color: scientist.primaryColor,
        radius: 2.8,
        damage: 20.0,
        life: 0.8,
      ));
    } else if (scientist.weaponId == 'bomb_launcher') {
      _bullets.add(_SimBullet(
        pos: shipMuzzle,
        vel: const Offset(0, -160),
        color: scientist.primaryColor,
        radius: 6.5,
        damage: 75.0,
        life: 1.0,
        isBomb: true,
      ));
    } else {
      // Blaster
      _bullets.add(_SimBullet(
        pos: shipMuzzle,
        vel: const Offset(0, -280),
        color: scientist.primaryColor,
        radius: 4.0,
        damage: 45.0,
        life: 0.8,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scientist = widget.scientist;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
            Navigator.of(context).pop();
            widget.game.playSfx('powerup.wav');
            widget.game.startFairGame(scientist);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.backspace) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scientist.primaryColor.withOpacity(0.6),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scientist.primaryColor.withOpacity(0.2),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: scientist.primaryColor, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            scientist.imagePath,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scientist.weaponName.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: scientist.primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${scientist.name} • ${scientist.weaponStyle}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Simulation Screen
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        // Live Simulation Paint
                        CustomPaint(
                          size: const Size(double.infinity, 180),
                          painter: _SimulationPainter(
                            scientist: scientist,
                            bullets: _bullets,
                            sparks: _sparks,
                            asteroidPos: _asteroidPos,
                            asteroidRadius: _asteroidRadius,
                            asteroidFlash: _asteroidFlashTimer > 0,
                          ),
                        ),
                        // Top Badge: "SIMULAÇÃO EM TEMPO REAL"
                        Positioned(
                          top: 8,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.redAccent, size: 6),
                                SizedBox(width: 4),
                                Text(
                                  'SIMULAÇÃO AO VIVO',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 8,
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stats Bars: Cadência, Área, Poder
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildStatBar('CADÊNCIA (VELOCIDADE)', scientist.cadenceRating, Colors.cyanAccent),
                        const SizedBox(height: 6),
                        _buildStatBar('ÁREA DE COBERTURA', scientist.areaRating, Colors.greenAccent),
                        const SizedBox(height: 6),
                        _buildStatBar('PODER DE IMPACTO', scientist.powerRating, Colors.orangeAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Kid Friendly Tip Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scientist.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scientist.primaryColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates, color: scientist.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scientist.kidTip,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('VER OUTRAS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.game.playSfx('powerup.wav');
                            widget.game.startFairGame(scientist);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scientist.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'ESCOLHER ESTA!',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 155,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              final active = index < value;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SimBullet {
  Offset pos;
  Offset vel;
  Color color;
  double radius;
  double damage;
  double life;
  bool isBomb;

  _SimBullet({
    required this.pos,
    required this.vel,
    required this.color,
    required this.radius,
    required this.damage,
    required this.life,
    this.isBomb = false,
  });
}

class _SimSpark {
  Offset pos;
  Offset vel;
  Color color;
  double life;

  _SimSpark({
    required this.pos,
    required this.vel,
    required this.color,
    required this.life,
  });
}

class _SimulationPainter extends CustomPainter {
  final Scientist scientist;
  final List<_SimBullet> bullets;
  final List<_SimSpark> sparks;
  final Offset asteroidPos;
  final double asteroidRadius;
  final bool asteroidFlash;

  _SimulationPainter({
    required this.scientist,
    required this.bullets,
    required this.sparks,
    required this.asteroidPos,
    required this.asteroidRadius,
    required this.asteroidFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Scale coordinates so (140, 180) maps nicely across dialog width
    final scaleX = size.width / 280.0;
    final scaleY = size.height / 180.0;

    // Draw Dummy Asteroid
    final mappedAsteroid = Offset(asteroidPos.dx * scaleX, asteroidPos.dy * scaleY);
    final astPaint = Paint()
      ..color = asteroidFlash ? Colors.white : Colors.grey[700]!
      ..style = PaintingStyle.fill;
    final astBorder = Paint()
      ..color = asteroidFlash ? Colors.yellowAccent : Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(mappedAsteroid, asteroidRadius * scaleX, astPaint);
    canvas.drawCircle(mappedAsteroid, asteroidRadius * scaleX, astBorder);

    // Draw Ship at Bottom Center
    final shipCenter = Offset(size.width / 2, size.height - 24);
    final shipPaint = Paint()
      ..color = scientist.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(shipCenter.dx, shipCenter.dy - 16);
    path.lineTo(shipCenter.dx - 12, shipCenter.dy + 12);
    path.lineTo(shipCenter.dx, shipCenter.dy + 6);
    path.lineTo(shipCenter.dx + 12, shipCenter.dy + 12);
    path.close();
    canvas.drawPath(path, shipPaint);

    // Draw Thruster flame
    final flamePaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;
    final flamePath = Path();
    flamePath.moveTo(shipCenter.dx - 4, shipCenter.dy + 8);
    flamePath.lineTo(shipCenter.dx + 4, shipCenter.dy + 8);
    flamePath.lineTo(shipCenter.dx, shipCenter.dy + 16);
    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);

    // Draw Bullets
    for (final b in bullets) {
      final bPos = Offset(b.pos.dx * scaleX, b.pos.dy * scaleY);
      final bulletPaint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(bPos, b.radius * scaleX, bulletPaint);

      // Glow ring for bombs
      if (b.isBomb) {
        final glowPaint = Paint()
          ..color = b.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(bPos, (b.radius + 4) * scaleX, glowPaint);
      }
    }

    // Draw Sparks
    for (final s in sparks) {
      final sPos = Offset(s.pos.dx * scaleX, s.pos.dy * scaleY);
      final sparkPaint = Paint()
        ..color = s.color.withOpacity((s.life / 0.6).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sPos, 1.8, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimulationPainter oldDelegate) => true;
}
