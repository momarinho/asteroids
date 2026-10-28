import 'dart:math' as math;
import 'dart:ui';

/// Helpers de brilho neon usados por naves, tiros, meteoros e partículas.
///
/// O "bloom" é simulado com camadas translúcidas desenhadas em
/// `BlendMode.plus` (brilho aditivo), o que é barato mesmo com dezenas de
/// objetos na tela. Apenas objetos únicos (como a nave do jogador) usam
/// `MaskFilter.blur` de verdade.
class Glow {
  /// Permite desligar todos os brilhos caso a máquina da feira engasgue.
  static bool enabled = true;

  static final MaskFilter _heroBlur = MaskFilter.blur(BlurStyle.normal, 5.0);

  /// Contorno com halo neon: duas camadas aditivas largas + traço nítido.
  static void strokePath(
    Canvas canvas,
    Path path,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    if (enabled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.10 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 5.5
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.22 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 2.6
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Igual a [strokePath], mas com blur real. Use só em objetos únicos.
  static void heroStrokePath(
    Canvas canvas,
    Path path,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    if (enabled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.55 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3.2
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = _heroBlur
          ..blendMode = BlendMode.plus,
      );
    }
    strokePath(canvas, path, color, width: width, intensity: enabled ? intensity * 0.6 : 0);
  }

  /// Contorno circular com halo neon (anéis de explosão, escudos etc.).
  static void strokeCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    strokePath(canvas, path, color, width: width, intensity: intensity);
  }

  /// Esfera luminosa: halo aditivo em camadas + núcleo quase branco.
  static void orb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double intensity = 1.0,
  }) {
    if (enabled) {
      canvas.drawCircle(
        center,
        radius * 3.4,
        Paint()
          ..color = color.withValues(alpha: 0.07 * intensity)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        center,
        radius * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.18 * intensity)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        center,
        radius * 1.4,
        Paint()
          ..color = color.withValues(alpha: 0.40 * intensity)
          ..blendMode = BlendMode.plus,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.85)!,
    );
  }

  /// Faísca/partícula brilhante, mais leve que [orb] (usada às centenas).
  static void spark(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final a = alpha.clamp(0.0, 1.0);
    if (enabled) {
      canvas.drawCircle(
        center,
        radius * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.16 * a)
          ..blendMode = BlendMode.plus,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: a)
        ..blendMode = enabled ? BlendMode.plus : BlendMode.srcOver,
    );
  }

  /// Interpola suavemente entre duas cores em [t] (0..1).
  static Color mix(Color a, Color b, double t) =>
      Color.lerp(a, b, math.min(1.0, math.max(0.0, t)))!;
}
