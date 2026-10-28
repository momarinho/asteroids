import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'package:asteroids/constants.dart';

class Star {
  Vector2 position;
  final int layer;
  final double twinklePhase;
  final double twinkleSpeed;
  final Color tint;

  Star({
    required this.position,
    required this.layer,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.tint,
  });
}

/// Fundo espacial: gradiente profundo, nebulosa que muda de cor conforme a
/// fase da partida e estrelas com parallax em 3 camadas e cintilação.
class StarfieldComponent extends Component with HasGameReference<AsteroidsGame> {
  final int numStars;
  final List<Star> stars = [];
  final Vector2 drift = Vector2(-8.0, -4.0);

  /// Tempo acumulado (congela junto com a pausa do motor).
  double _time = 0.0;

  /// Segundos de partida "exibidos" no fundo; suaviza as trocas de fase.
  double _shownElapsed = 0.0;

  final Paint _starPaint = Paint()..style = PaintingStyle.fill;
  final Paint _haloPaint = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  StarfieldComponent({this.numStars = 170});

  // Paleta da nebulosa por instante da partida (segundos decorridos).
  // Acompanha as fases de dificuldade do AsteroidField (0/50/105/150/180s).
  static const List<({double t, Color a, Color b})> _paletteStops = [
    (t: 0.0, a: Color(0xFF1E3C9E), b: Color(0xFF0E8A9E)), // azul / turquesa
    (t: 50.0, a: Color(0xFF1E3C9E), b: Color(0xFF0E8A9E)),
    (t: 105.0, a: Color(0xFF5B2A9E), b: Color(0xFF1E3C9E)), // violeta
    (t: 150.0, a: Color(0xFFB35A12), b: Color(0xFF7A2A9E)), // âmbar
    (t: 180.0, a: Color(0xFFC4122A), b: Color(0xFF8A3A0E)), // tempestade final
  ];

  static const List<Color> _starTints = [
    Color(0xFFFFFFFF),
    Color(0xFFCFE3FF),
    Color(0xFFFFF1D6),
    Color(0xFFBFD4FF),
  ];

  @override
  void onMount() {
    super.onMount();
    _initializeStars();
  }

  void _initializeStars() {
    final random = math.Random();
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    stars.clear();
    for (var i = 0; i < numStars; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      // Mais estrelas distantes (camada 1) do que próximas (camada 3)
      final roll = random.nextDouble();
      final layer = roll < 0.55 ? 1 : (roll < 0.87 ? 2 : 3);
      stars.add(
        Star(
          position: Vector2(x, y),
          layer: layer,
          twinklePhase: random.nextDouble() * math.pi * 2,
          twinkleSpeed: 0.8 + random.nextDouble() * 2.2,
          tint: _starTints[random.nextInt(_starTints.length)],
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Instante da partida que o fundo deve refletir (calmo fora do jogo)
    final targetElapsed = game.state == GameState.playing
        ? (AsteroidsGame.fairRoundDuration - game.timeRemaining)
            .clamp(0.0, AsteroidsGame.fairRoundDuration)
        : 0.0;
    _shownElapsed += (targetElapsed - _shownElapsed) * math.min(1.0, dt * 2.5);

    if (stars.isEmpty) return;

    final playerVelocity = game.player.velocity;
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    for (final star in stars) {
      // Parallax: camadas próximas reagem mais ao movimento da nave
      final multiplier = star.layer * 0.05;

      star.position.x += (drift.x * star.layer * 0.6 - playerVelocity.x * multiplier) * dt;
      star.position.y += (drift.y * star.layer * 0.6 - playerVelocity.y * multiplier) * dt;

      if (star.position.x < 0) {
        star.position.x = width;
      } else if (star.position.x > width) {
        star.position.x = 0;
      }

      if (star.position.y < 0) {
        star.position.y = height;
      } else if (star.position.y > height) {
        star.position.y = 0;
      }
    }
  }

  ({Color a, Color b}) _paletteAt(double t) {
    for (var i = 0; i < _paletteStops.length - 1; i++) {
      final s0 = _paletteStops[i];
      final s1 = _paletteStops[i + 1];
      if (t <= s1.t) {
        final span = s1.t - s0.t;
        final k = span <= 0 ? 1.0 : ((t - s0.t) / span).clamp(0.0, 1.0);
        return (a: Color.lerp(s0.a, s1.a, k)!, b: Color.lerp(s0.b, s1.b, k)!);
      }
    }
    final last = _paletteStops.last;
    return (a: last.a, b: last.b);
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color, double alpha) {
    final shader = RadialGradient(
      colors: [
        color.withValues(alpha: alpha.clamp(0.0, 1.0)),
        color.withValues(alpha: alpha.clamp(0.0, 1.0) * 0.35),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    // 1. Gradiente base: azul-marinho quase preto → preto
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060A1A), Color(0xFF010208)],
        ).createShader(Rect.fromLTWH(0, 0, width, height)),
    );

    // 2. Nebulosa em 3 manchas suaves que respiram devagar
    final palette = _paletteAt(_shownElapsed);
    final stormK = ((_shownElapsed - 150.0) / 30.0).clamp(0.0, 1.0);
    final stormPulse = 1.0 + 0.35 * stormK * (0.5 + 0.5 * math.sin(_time * 4.0));

    _drawBlob(
      canvas,
      Offset(width * 0.22 + math.sin(_time * 0.05) * 60, height * 0.30 + math.cos(_time * 0.04) * 40),
      520,
      palette.a,
      0.30 * stormPulse,
    );
    _drawBlob(
      canvas,
      Offset(width * 0.80 + math.cos(_time * 0.045) * 70, height * 0.72 + math.sin(_time * 0.06) * 50),
      480,
      palette.b,
      0.26 * stormPulse,
    );
    _drawBlob(
      canvas,
      Offset(width * 0.55 + math.sin(_time * 0.03) * 90, height * 0.48),
      720,
      Color.lerp(palette.a, palette.b, 0.5)!,
      0.10 * stormPulse,
    );

    // 3. Estrelas com cintilação, tamanho e brilho por camada de profundidade
    for (final star in stars) {
      final twinkle = 0.55 + 0.45 * math.sin(_time * star.twinkleSpeed + star.twinklePhase);

      double size;
      double baseAlpha;
      switch (star.layer) {
        case 1:
          size = 1.0;
          baseAlpha = 0.45;
          break;
        case 2:
          size = 1.5;
          baseAlpha = 0.70;
          break;
        case 3:
        default:
          size = 2.2;
          baseAlpha = 1.0;
          break;
      }

      final alpha = baseAlpha * twinkle;
      final center = Offset(star.position.x, star.position.y);

      // Estrelas próximas ganham um halo aditivo discreto
      if (star.layer == 3 && Glow.enabled) {
        _haloPaint.color = star.tint.withValues(alpha: 0.18 * twinkle);
        canvas.drawCircle(center, size * 3.2, _haloPaint);
      }

      _starPaint.color = star.tint.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, size, _starPaint);
    }
  }
}
