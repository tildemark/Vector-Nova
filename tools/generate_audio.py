import wave
import math
import struct
import random
import os

SAMPLE_RATE = 44100

def save_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1) # mono
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        raw_data = bytearray()
        for sample in samples:
            # clamp between -1.0 and 1.0
            s = max(-1.0, min(1.0, sample))
            int_sample = int(s * 32767.0)
            raw_data.extend(struct.pack('<h', int_sample))
        wav_file.writeframes(raw_data)
    print(f"Generated: {filename} ({len(samples)} samples)")

# 1. Player Laser Shoot
def generate_laser():
    duration = 0.16
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        freq = 950.0 * (1.0 - progress * 0.75) # 950Hz down to 237Hz
        phase = 2.0 * math.pi * freq * t
        # Triangle/saw blend
        wave_val = (math.asin(math.sin(phase)) * (2.0 / math.pi)) * 0.5 + math.sin(phase) * 0.5
        env = math.exp(-progress * 6.0)
        samples.append(wave_val * env * 0.65)
    return samples

# 2. Small Enemy Explosion
def generate_explosion_small():
    duration = 0.35
    n = int(SAMPLE_RATE * duration)
    samples = []
    noise_filt = 0.0
    for i in range(n):
        progress = i / n
        raw_noise = random.uniform(-1.0, 1.0)
        # Lowpass filter
        noise_filt = noise_filt * 0.85 + raw_noise * 0.15
        # Pitch rumble drop
        rumble = math.sin(2.0 * math.pi * (140.0 * (1.0 - progress * 0.7)) * (i / SAMPLE_RATE))
        combined = noise_filt * 0.7 + rumble * 0.3
        env = math.exp(-progress * 5.0)
        samples.append(combined * env * 0.8)
    return samples

# 3. Heavy Boss Explosion
def generate_explosion_heavy():
    duration = 0.95
    n = int(SAMPLE_RATE * duration)
    samples = []
    noise_filt = 0.0
    for i in range(n):
        progress = i / n
        raw_noise = random.uniform(-1.0, 1.0)
        noise_filt = noise_filt * 0.92 + raw_noise * 0.08
        sub_bass = math.sin(2.0 * math.pi * (65.0 * (1.0 - progress * 0.6)) * (i / SAMPLE_RATE))
        combined = noise_filt * 0.6 + sub_bass * 0.5
        env = (1.0 - progress) * math.exp(-progress * 2.8)
        samples.append(combined * env * 0.9)
    return samples

# 4. Bullet Absorption (Escort shield deflection ping)
def generate_bullet_absorb():
    duration = 0.18
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        tone1 = math.sin(2.0 * math.pi * 1760.0 * t)
        tone2 = math.sin(2.0 * math.pi * 2640.0 * t)
        env = math.exp(-progress * 12.0)
        samples.append((tone1 * 0.6 + tone2 * 0.4) * env * 0.6)
    return samples

# 5. Graze Near-Miss Spark
def generate_graze():
    duration = 0.14
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        freq = 2400.0 + progress * 800.0
        tone = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-progress * 14.0)
        samples.append(tone * env * 0.5)
    return samples

# 6. Scrap Crystal Collect
def generate_scrap_pickup():
    duration = 0.12
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        # High crystal arpeggio
        f = 1320.0 if progress < 0.5 else 1760.0
        tone = math.sin(2.0 * math.pi * f * t)
        env = math.exp(-((progress % 0.5) / 0.5) * 8.0)
        samples.append(tone * env * 0.45)
    return samples

# 7. Power-up Item [P] Collect (Arcade chime)
def generate_powerup():
    duration = 0.32
    n = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.5] # C5, E5, G5, C6
    for i in range(n):
        t = i / SAMPLE_RATE
        note_idx = min(3, int((i / n) * 4))
        freq = notes[note_idx]
        note_phase = (i / n) * 4.0 - note_idx
        env = math.exp(-note_phase * 4.5)
        tone = math.sin(2.0 * math.pi * freq * t) + math.sin(4.0 * math.pi * freq * t) * 0.3
        samples.append(tone * env * 0.55)
    return samples

# 8. EMP Detonation (Screen-clearing bass boom)
def generate_emp():
    duration = 0.6
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        freq = 240.0 * math.exp(-progress * 5.0) + 35.0
        tone = math.sin(2.0 * math.pi * freq * t)
        noise = random.uniform(-0.3, 0.3) * math.exp(-progress * 3.0)
        env = math.exp(-progress * 3.5)
        samples.append((tone * 0.8 + noise) * env * 0.85)
    return samples

# 9. Swarm Missile Launch
def generate_missile_launch():
    duration = 0.28
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        freq = 300.0 + progress * 600.0
        tone = math.sin(2.0 * math.pi * freq * t)
        noise = random.uniform(-0.4, 0.4)
        env = math.exp(-progress * 4.0)
        samples.append((tone * 0.5 + noise * 0.5) * env * 0.6)
    return samples

# 10. Hyper-Beam Pulse
def generate_hyper_beam():
    duration = 0.3
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = i / n
        phase = 2.0 * math.pi * 180.0 * t
        saw = 2.0 * (phase / (2.0 * math.pi) - math.floor(phase / (2.0 * math.pi) + 0.5))
        buzz = math.sin(2.0 * math.pi * 60.0 * t)
        env = math.sin(math.pi * progress)
        samples.append(saw * 0.6 * buzz * env * 0.7)
    return samples

# ----------------- ARCADE BGM TRACKS -----------------
# 11. Stage 1 Combat BGM (135 BPM driving synthwave loop, ~14 seconds seamless)
def generate_stage1_bgm():
    bpm = 135.0
    beat_dur = 60.0 / bpm # ~0.444s
    bars = 8 # 32 beats = ~14.22s
    total_duration = beat_dur * 4.0 * bars
    n = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * n

    # Bassline notes: F# minor progression [F#2, A2, E2, D2]
    root_freqs = [92.50, 110.0, 82.41, 73.42]

    # Generate kick & snare drum rhythm
    for beat in range(bars * 4):
        beat_start = int(beat * beat_dur * SAMPLE_RATE)
        is_snare = (beat % 2 == 1) # beat 2 and 4
        # Kick drum
        kick_len = int(0.18 * SAMPLE_RATE)
        for j in range(min(kick_len, n - beat_start)):
            t = j / SAMPLE_RATE
            p = j / kick_len
            f = 140.0 * math.exp(-p * 18.0) + 40.0
            kick_val = math.sin(2.0 * math.pi * f * t) * math.exp(-p * 8.0) * 0.5
            samples[beat_start + j] += kick_val

        # Snare drum
        if is_snare:
            snare_len = int(0.22 * SAMPLE_RATE)
            noise_f = 0.0
            for j in range(min(snare_len, n - beat_start)):
                p = j / snare_len
                noise_f = noise_f * 0.75 + random.uniform(-1.0, 1.0) * 0.25
                snare_val = noise_f * math.exp(-p * 6.5) * 0.35
                samples[beat_start + j] += snare_val

    # Driving 16th note arpeggiated bass synth
    sixteenth_dur = beat_dur / 4.0
    total_16ths = bars * 16
    for step in range(total_16ths):
        step_start = int(step * sixteenth_dur * SAMPLE_RATE)
        bar_idx = (step // 16) % len(root_freqs)
        base_f = root_freqs[bar_idx]
        
        # 16th note pattern octave bounce
        mult = 1.0 if (step % 2 == 0) else 2.0
        if step % 4 == 3: mult = 1.5
        note_freq = base_f * mult
        note_len = int(sixteenth_dur * 0.85 * SAMPLE_RATE)
        
        for j in range(min(note_len, n - step_start)):
            t = j / SAMPLE_RATE
            p = j / note_len
            phase = 2.0 * math.pi * note_freq * t
            saw = 2.0 * (phase / (2.0 * math.pi) - math.floor(phase / (2.0 * math.pi) + 0.5))
            env = math.exp(-p * 5.0)
            samples[step_start + j] += saw * env * 0.18

    # Normalize BGM to avoid clipping
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.95:
        samples = [s / max_val * 0.9 for s in samples]
    return samples

# 12. Title Theme BGM (Ambient Cyberpunk Arp, ~10s loop)
def generate_title_bgm():
    total_duration = 10.66
    n = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * n
    # Em9 arpeggio chord [E3, B3, D4, F#4, G4]
    chord_freqs = [164.81, 246.94, 293.66, 369.99, 392.00]
    step_dur = 0.333
    total_steps = int(total_duration / step_dur)

    for step in range(total_steps):
        step_start = int(step * step_dur * SAMPLE_RATE)
        f = chord_freqs[step % len(chord_freqs)]
        note_len = int(step_dur * 2.2 * SAMPLE_RATE) # overlapping delay tail
        for j in range(min(note_len, n - step_start)):
            t = j / SAMPLE_RATE
            p = j / note_len
            tone = math.sin(2.0 * math.pi * f * t) + math.sin(4.0 * math.pi * f * t) * 0.25
            env = math.exp(-p * 3.0)
            samples[step_start + j] += tone * env * 0.22

    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.95:
        samples = [s / max_val * 0.9 for s in samples]
    return samples

if __name__ == '__main__':
    print("Synthesizing Vector Nova Audio...")
    save_wav("assets/audio/sfx/laser_player.wav", generate_laser())
    save_wav("assets/audio/sfx/explosion_small.wav", generate_explosion_small())
    save_wav("assets/audio/sfx/explosion_heavy.wav", generate_explosion_heavy())
    save_wav("assets/audio/sfx/bullet_absorb.wav", generate_bullet_absorb())
    save_wav("assets/audio/sfx/graze.wav", generate_graze())
    save_wav("assets/audio/sfx/scrap_pickup.wav", generate_scrap_pickup())
    save_wav("assets/audio/sfx/powerup_pickup.wav", generate_powerup())
    save_wav("assets/audio/sfx/emp_detonate.wav", generate_emp())
    save_wav("assets/audio/sfx/missile_launch.wav", generate_missile_launch())
    save_wav("assets/audio/sfx/hyper_beam.wav", generate_hyper_beam())
    
    print("Synthesizing Arcade Music Tracks...")
    save_wav("assets/audio/bgm/bgm_stage1.wav", generate_stage1_bgm())
    save_wav("assets/audio/bgm/bgm_title.wav", generate_title_bgm())
    print("All audio synthesis complete!")
