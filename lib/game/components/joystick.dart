import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';

class GameJoystick extends PositionComponent with HasGameReference<AsteroidsGame>, DragCallbacks {
  final double backgroundRadius = 60.0;
  final double knobRadius = 22.0;
  
  Vector2 knobPosition = Vector2.zero();
  Vector2 stickInput = Vector2.zero();
  bool isDragging = false;

  GameJoystick() {
    anchor = Anchor.center;
    // Position in the bottom-left corner of the 1280x720 screen
    position = Vector2(120, 600);
    size = Vector2.all(60.0 * 2);
  }

  @override
  void render(Canvas canvas) {
    if (game.state != GameState.playing) return;
    
    super.render(canvas);
    
    // Translate canvas to the center of the joystick for easy drawing
    canvas.translate(backgroundRadius, backgroundRadius);

    // Draw background outer ring (semi-transparent cyan outline)
    final bgPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, backgroundRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, backgroundRadius, borderPaint);

    // Draw knob (glowing cyan circle)
    final knobPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Draw subtle shadow for the knob
    final shadowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(Offset(knobPosition.x, knobPosition.y), knobRadius, shadowPaint);
    canvas.drawCircle(Offset(knobPosition.x, knobPosition.y), knobRadius, knobPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state != GameState.playing) {
      knobPosition.setZero();
      stickInput.setZero();
      isDragging = false;
      return;
    }

    if (isDragging) {
      // Input is determined by the drag
      stickInput = knobPosition / backgroundRadius;
    } else {
      // On PC, visually reflect keyboard presses!
      final keys = game.keysPressed;
      final targetKnob = Vector2.zero();

      if (keys.contains(LogicalKeyboardKey.arrowLeft) || keys.contains(LogicalKeyboardKey.keyA)) {
        targetKnob.x -= 1.0;
      }
      if (keys.contains(LogicalKeyboardKey.arrowRight) || keys.contains(LogicalKeyboardKey.keyD)) {
        targetKnob.x += 1.0;
      }
      if (keys.contains(LogicalKeyboardKey.arrowUp) || keys.contains(LogicalKeyboardKey.keyW)) {
        targetKnob.y -= 1.0;
      }
      if (keys.contains(LogicalKeyboardKey.arrowDown) || keys.contains(LogicalKeyboardKey.keyS)) {
        targetKnob.y += 1.0;
      }

      if (targetKnob.length > 0) {
        targetKnob.normalize();
        targetKnob.scale(backgroundRadius * 0.7);
      }

      // Smoothly slide the knob towards target
      knobPosition.lerp(targetKnob, 15 * dt);
      stickInput = knobPosition / backgroundRadius;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (game.state != GameState.playing) return;
    super.onDragStart(event);
    isDragging = true;
    _updateKnobPosition(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.state != GameState.playing) return;
    super.onDragUpdate(event);
    _updateKnobPosition(event.localPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    knobPosition.setZero();
    stickInput.setZero();
  }

  void _updateKnobPosition(Vector2 localPos) {
    // localPos is relative to the top-left of the component
    // Convert it relative to the center
    final centerOffset = localPos - Vector2.all(backgroundRadius);
    final distance = centerOffset.length;

    if (distance <= backgroundRadius) {
      knobPosition.setFrom(centerOffset);
    } else {
      knobPosition.setFrom(centerOffset.normalized() * backgroundRadius);
    }
  }
}
