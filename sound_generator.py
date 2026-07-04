import math
import struct
import wave
from pathlib import Path

def save_wav(filename: Path, samples: list[float], sample_rate: int = 22050) -> None:
    filename.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(filename), 'wb') as wav_file:
        # Channels: 1 (mono), Sample width: 2 bytes (16-bit PCM), Framerate: sample_rate
        wav_file.setparams((1, 2, sample_rate, len(samples), 'NONE', 'not compressed'))
        for sample in samples:
            val = max(-1.0, min(1.0, sample))
            int_val = int(val * 32767)
            wav_file.writeframes(struct.pack('<h', int_val))

def generate_low_health(filepath: Path) -> None:
    sample_rate = 22050
    samples = []
    # Alarm double tone
    for i in range(int(sample_rate * 0.12)):
        t = i / sample_rate
        samples.append(0.25 * math.sin(2 * math.pi * 380 * t))
    for _ in range(int(sample_rate * 0.08)):
        samples.append(0.0)
    for i in range(int(sample_rate * 0.12)):
        t = i / sample_rate
        samples.append(0.25 * math.sin(2 * math.pi * 380 * t))
    save_wav(filepath, samples, sample_rate)

def generate_purchase(filepath: Path) -> None:
    sample_rate = 22050
    samples = []
    # Coin sound: rising notes
    n1 = int(sample_rate * 0.08)
    for i in range(n1):
        t = i / sample_rate
        samples.append(0.2 * math.sin(2 * math.pi * 987 * t))
    n2 = int(sample_rate * 0.25)
    for i in range(n2):
        t = i / sample_rate
        fade = 1.0 - (i / n2)
        samples.append(0.2 * fade * math.sin(2 * math.pi * 1318 * t))
    save_wav(filepath, samples, sample_rate)

def generate_powerup(filepath: Path) -> None:
    sample_rate = 22050
    samples = []
    freqs = [523, 659, 784, 1046]
    note_dur = 0.06
    for f in freqs:
        n = int(sample_rate * note_dur)
        for i in range(n):
            t = i / sample_rate
            fade = 1.0 - (i / n) * 0.3
            samples.append(0.2 * fade * math.sin(2 * math.pi * f * t))
    save_wav(filepath, samples, sample_rate)

def generate_music(filepath: Path) -> None:
    sample_rate = 22050
    bpm = 120
    beat_len = 60.0 / bpm  # 0.5s per beat
    
    # 16 beats progression: Am (A, A, A, A), F (F, F, F, F), C (C, C, C, C), G (G, G, G, G)
    bass_freqs = [110, 110, 110, 110, 87.3, 87.3, 87.3, 87.3, 130.8, 130.8, 130.8, 130.8, 98, 98, 98, 98]
    melody_freqs = [
        440, 523, 587, 659,
        698, 659, 587, 523,
        523, 587, 659, 784,
        784, 698, 587, 440,
    ]
    
    total_samples = int(sample_rate * beat_len * 16)
    samples = [0.0] * total_samples
    
    for beat in range(16):
        start_idx = int(beat * beat_len * sample_rate)
        end_idx = int((beat + 1) * beat_len * sample_rate)
        note_len = end_idx - start_idx
        
        b_freq = bass_freqs[beat]
        m_freq = melody_freqs[beat]
        
        for i in range(note_len):
            idx = start_idx + i
            t = i / sample_rate
            
            # Bass wave (triangle wave: value goes linearly up and down)
            # period = 1.0 / b_freq
            # pos in period = (t * b_freq) % 1.0
            pos = (t * b_freq) % 1.0
            if pos < 0.25:
                bass_val = pos * 4
            elif pos < 0.75:
                bass_val = 2 - pos * 4
            else:
                bass_val = pos * 4 - 4
            bass_val *= 0.12  # volume
            
            # Melody wave: sine wave with fast decay envelope
            envelope = math.exp(-3.0 * (i / note_len))
            melody_val = 0.06 * envelope * math.sin(2 * math.pi * m_freq * t)
            
            samples[idx] = bass_val + melody_val
            
    save_wav(filepath, samples, sample_rate)

def generate_all_missing_sounds() -> None:
    sounds_dir = Path("assets/sounds")
    sounds_dir.mkdir(parents=True, exist_ok=True)
    
    music_path = sounds_dir / "music.wav"
    low_health_path = sounds_dir / "low_health.wav"
    purchase_path = sounds_dir / "purchase.wav"
    powerup_path = sounds_dir / "powerup.wav"
    
    if not music_path.exists():
        print("Generating music.wav...")
        generate_music(music_path)
    if not low_health_path.exists():
        print("Generating low_health.wav...")
        generate_low_health(low_health_path)
    if not purchase_path.exists():
        print("Generating purchase.wav...")
        generate_purchase(purchase_path)
    if not powerup_path.exists():
        print("Generating powerup.wav...")
        generate_powerup(powerup_path)

if __name__ == "__main__":
    generate_all_missing_sounds()
