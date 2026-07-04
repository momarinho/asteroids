shake_timer = 0.0
shake_intensity = 0.0
shake_duration = 0.0

def trigger_screen_shake(duration: float, intensity: float) -> None:
    global shake_timer, shake_intensity, shake_duration
    shake_timer = duration
    shake_intensity = intensity
    shake_duration = duration
