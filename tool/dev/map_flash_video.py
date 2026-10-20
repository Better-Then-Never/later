"""Flashing bubbles in a screen recording of the map (docs/map/FLASH_FIX.md).

   python -I tool/dev/map_flash_video.py video.mp4 [--from S] [--to S]

Reads every frame at the recorder's own rate (no resampling), and per frame
measures in the map part of the screen:
- solid: pixels of the bubbles' solid brand green (#56C92E, and the green
  pin's fill), i.e. how much bubble is drawn;
- pale: pixels on the line from the map's ground colour to that green,
  between 35 % and 80 % of the way (a bubble or pin drawn see-through; parks,
  woods and the heat are mixed at 26 % or less, so they do not count).

Flags flashes: the solid area jumps by more than 25 % (and 60 pixels at the
180x400 reading size) and comes back, either way (a bubble
drawn for a moment, or gone for a moment; back within 200 ms: the level
changes of the owner's recording took up to 160 ms to come back). The
frames are all read, but
compared about 33 ms apart (the value shown at each 1/30 s, twice, half a
step apart), so a fast recording (120 fps, where a flash changes a little
each frame) and a 30 fps one are judged alike. Light theme only.

Prints JSON: frames, fps, the flash events (time, kind, size) and the frames
with the most pale green.
"""

import json
import subprocess
import sys
import tempfile

import imageio_ffmpeg
import numpy as np

W, H = 180, 400
GREEN = np.array([86, 201, 46], np.float32)
GROUND = np.array([243, 243, 240], np.float32)


def _decode(path, start=None, end=None):
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    args = [ff, "-hide_banner", "-loglevel", "info"]
    if start is not None:
        args += ["-ss", str(start)]
    if end is not None:
        args += ["-to", str(end)]
    args += ["-i", path, "-fps_mode", "passthrough",
             "-vf", f"scale={W}:{H}:flags=area,showinfo",
             "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    with tempfile.TemporaryFile() as out:
        proc = subprocess.run(args, stdout=out, stderr=subprocess.PIPE, check=True)
        log = proc.stderr.decode("utf-8", "replace")
        out.seek(0)
        data = np.frombuffer(out.read(), np.uint8)
    times = [float(line.split("pts_time:")[1].split()[0])
             for line in log.splitlines() if "pts_time:" in line]
    n = min(len(times), data.size // (W * H * 3))
    return np.array(times[:n]) + (start or 0), data[: n * W * H * 3].reshape(n, H, W, 3)


def _map_area(frame):
    # Below the status bar and the filter/streak row, above the navigation
    # pill, left of the zoom and location buttons.
    return frame[int(H * 0.11): int(H * 0.82), : int(W * 0.80)]


def measure(frame):
    px = _map_area(frame).astype(np.float32).reshape(-1, 3)
    axis = GREEN - GROUND
    t = ((px - GROUND) @ axis) / float(axis @ axis)
    off = np.linalg.norm(px - (GROUND + t[:, None] * axis), axis=1)
    on_line = off < 18
    solid = on_line & (t > 0.85) & (t < 1.15)
    pale = on_line & (t > 0.35) & (t <= 0.8)
    return int(solid.sum()), int(pale.sum())


def flashes(times, solid, window=0.2):
    events = []
    n = len(solid)
    i = 1
    while i < n:
        before = solid[i - 1]
        jump = solid[i] - before
        if abs(jump) > max(60, 0.25 * max(before, 1)):
            j = i + 1
            while j < n and times[j] - times[i] <= window:
                back = solid[j] - solid[i]
                if back * jump < 0 and abs(solid[j] - before) < 0.4 * abs(jump):
                    events.append({
                        "t": round(float(times[i]), 3),
                        "kind": "up" if jump > 0 else "down",
                        "size": int(jump),
                        "frames": j - i,
                    })
                    i = j
                    break
                j += 1
        i += 1
    return events


def held(times, values, step, phase):
    """The value on screen at each step from the start (+ phase)."""
    grid = np.arange(times[0] + phase, times[-1], step)
    idx = np.searchsorted(times, grid, side="right") - 1
    return grid, values[np.clip(idx, 0, len(values) - 1)]


def events(times, solid):
    found = []
    for phase in (0.0, 1 / 60):
        grid, values = held(times, solid, 1 / 30, phase)
        for e in flashes(grid, values):
            if all(abs(e["t"] - f["t"]) > 0.05 for f in found):
                found.append(e)
    return sorted(found, key=lambda e: e["t"])


def main(argv):
    path = argv[0]
    start = float(argv[argv.index("--from") + 1]) if "--from" in argv else None
    end = float(argv[argv.index("--to") + 1]) if "--to" in argv else None
    times, frames = _decode(path, start, end)
    solid = np.zeros(len(frames), int)
    pale = np.zeros(len(frames), int)
    for i, f in enumerate(frames):
        solid[i], pale[i] = measure(f)
    span = float(times[-1] - times[0]) if len(times) > 1 else 0
    worst = np.argsort(-pale)[:8]
    print(json.dumps({
        "video": path,
        "frames": int(len(frames)),
        "fps": round((len(frames) - 1) / span, 1) if span else 0,
        "flashes": events(times, solid),
        "flash_count": len(events(times, solid)),
        "pale_peak_frames": [
            {"t": round(float(times[k]), 3), "pale": int(pale[k])} for k in sorted(worst)
        ],
    }, indent=1))


if __name__ == "__main__":
    main(sys.argv[1:])
