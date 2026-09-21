"""Prepare the CC0 wooden-table dice recording for the app (macOS afconvert)."""

import math
from pathlib import Path
import struct
import subprocess
import tempfile
import wave

root = Path(__file__).resolve().parent.parent
source = root / "scripts/audio-sources/dice-table-flem0527.mp3"
rate = 44100
with tempfile.TemporaryDirectory() as directory:
    decoded = Path(directory) / "decoded.wav"
    subprocess.run([
        "afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1",
        str(source), str(decoded),
    ], check=True)
    with wave.open(str(decoded)) as f:
        raw = f.readframes(f.getnframes())
    recording = [v / 32768 for (v,) in struct.iter_unpack("<h", raw)]

# Remove lead-in silence, then slow the actual clatter slightly to follow the
# 1.2-second roll. Preserve its irregular collisions and natural settling tail.
recording = recording[round(0.08 * rate):]
samples = [0.0] * round(1.36 * rate)
start = round(0.02 * rate)
speed = 0.88
for i in range(min(len(samples) - start, int((len(recording) - 1) / speed))):
    position = i * speed
    index = int(position)
    fraction = position - index
    samples[start + i] = recording[index] * (1 - fraction) + recording[index + 1] * fraction

# Increase the quiet rolling detail as well as peak volume. A smooth limiter
# controls the recording's very brief loud clicks without hard clipping.
# Target -20.9 dBFS RMS / -1.4 dBFS peak, leaving playback headroom.
peak_target = 0.85
rms_target = 0.09

def mastered(drive):
    signal = [math.tanh(s * drive) for s in samples]
    gain = peak_target / max(abs(s) for s in signal)
    return [s * gain for s in signal]

low, high = 1.0, 24.0
for _ in range(24):
    drive = (low + high) / 2
    candidate = mastered(drive)
    rms = math.sqrt(sum(s * s for s in candidate) / len(candidate))
    if rms < rms_target:
        low = drive
    else:
        high = drive
samples = mastered((low + high) / 2)

# Short fades prevent edit clicks while leaving the impact attack intact.
fade = round(rate * 0.005)
for i in range(fade):
    samples[start + i] *= i / fade
    samples[-1 - i] *= i / fade

out = root / "Dundaillereal/Resources/dice-roll.wav"
with wave.open(str(out), "wb") as f:
    f.setparams((1, 2, rate, 0, "NONE", "not compressed"))
    f.writeframes(b"".join(struct.pack("<h", round(s * 32767)) for s in samples))
print(out)
