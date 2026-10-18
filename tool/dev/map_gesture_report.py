"""What a screen recording of the map shows, frame by frame (docs/map/PERFORMANCE.md).

    python -I tool/dev/map_gesture_report.py <video.mp4> [--frames out.csv]

Reads a phone recording (adb shell screenrecord, variable frame rate: a frame
only when the screen changes) with the ffmpeg of imageio-ffmpeg, and prints a
JSON report:

- gaps: time between two recorded frames of 100 ms or more while the map is
  active (moving or under a finger). With the harness strip (MapHarnessStrip,
  --dart-define=MAP_HARNESS=true) the app draws every frame while active, so a
  gap is a stall. Without the strip (the owner's videos) every gap counts.
- frozen: spans of 150 ms or more where the map part of the screen does not
  change while the app keeps drawing (the strip ticks): the map stalled.
- empty: active frames showing neither heat nor markers (see _classify).
- heat_blinks: heat visible, then gone for some frames, then back.

Frames are read at 180x400 (a third of 540x1200) for speed; the strip is read
from the full-size top-left corner.
"""

import json
import subprocess
import sys
import tempfile

import imageio_ffmpeg
import numpy as np

W, H = 180, 400


def _decode(path):
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    with tempfile.TemporaryFile() as raw, tempfile.TemporaryFile() as small:
        # Full-size top-left corner (the strip) and the downscaled frame, in one
        # pass each; showinfo prints every frame's time.
        for target, vf in (
            (raw, "crop=40:20:0:0,showinfo"),
            (small, f"scale={W}:{H},showinfo"),
        ):
            proc = subprocess.run(
                [ff, "-hide_banner", "-loglevel", "info", "-i", path,
                 "-fps_mode", "passthrough", "-vf", vf,
                 "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                stdout=target, stderr=subprocess.PIPE, check=True)
            if target is raw:
                log = proc.stderr.decode("utf-8", "replace")
        times = [float(line.split("pts_time:")[1].split()[0])
                 for line in log.splitlines() if "pts_time:" in line]
        raw.seek(0)
        corners = np.frombuffer(raw.read(), np.uint8)
        small.seek(0)
        frames = np.frombuffer(small.read(), np.uint8)
    n = min(len(times), corners.size // (40 * 20 * 3), frames.size // (W * H * 3))
    corners = corners[: n * 40 * 20 * 3].reshape(n, 20, 40, 3)
    frames = frames[: n * W * H * 3].reshape(n, H, W, 3)
    return np.array(times[:n]), corners, frames


def _hsv(rgb):
    rgb = rgb.astype(np.float32) / 255
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    hue = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return hue, sat, mx


# The map part of the screen: below the status bar and the filter/streak row,
# above the navigation bar, left of the zoom and location buttons.
def _map_area(frame):
    return frame[int(H * 0.11): int(H * 0.82), : int(W * 0.80)]


def _classify(frame):
    """(heat pixels, marker pixels) in the map area, as fractions."""
    area = _map_area(frame)
    hue, sat, val = _hsv(area)
    # Pins and bubbles: saturated, bright (capsule colours, brand green).
    markers = (sat > 0.55) & (val > 0.45)
    # Heat: its warm part, a see-through yellow-orange haze (the base map has
    # green parks and blue water, but almost nothing warm; heat over a city
    # always has a warm core).
    tinted = (sat > 0.16) & (sat <= 0.55) & (val > 0.6)
    heat = tinted & (hue > 25) & (hue < 70)
    return float(heat.mean()), float(markers.mean())


def report(path, frames_csv=None):
    times, corners, frames = _decode(path)
    n = len(times)
    # The strip: first block flips every frame while active, second red/blue.
    block1 = corners[:, 7, 7].astype(int)
    block2 = corners[:, 7, 22].astype(int)
    red = (block2[:, 0] > 200) & (block2[:, 1] < 110) & (block2[:, 2] < 110)
    blue = (block2[:, 0] < 90) & (block2[:, 1] > 110) & (block2[:, 2] > 200)
    bw = (block1.max(-1) - block1.min(-1)) < 40
    # The strip is there when nearly every frame shows it.
    has_strip = bool(n and ((red | blue) & bw).mean() > 0.9)
    active = red if has_strip else np.ones(n, bool)
    tick = block1.mean(-1) > 128

    heat, markers = np.zeros(n), np.zeros(n)
    change = np.zeros(n)
    prev = None
    for i in range(n):
        heat[i], markers[i] = _classify(frames[i])
        area = _map_area(frames[i]).astype(np.int16)
        if prev is not None:
            change[i] = float(np.abs(area - prev).mean())
        prev = area
    # Calibrated on the owner's recording (owner4.mp4): no heat 0.000 to 0.004
    # (country, city, street), heat 0.017 to 0.39; no markers up to 0.0018, one
    # pin 0.0024 and more.
    heat_on = heat > 0.008
    markers_on = markers > 0.0022

    gaps = []
    for i in range(1, n):
        if not (active[i - 1] or active[i]):
            continue
        dt = (times[i] - times[i - 1]) * 1000
        if dt >= 100:
            gaps.append([round(times[i - 1], 3), round(dt)])

    frozen = []
    if has_strip:
        start = None
        for i in range(1, n):
            still = active[i] and change[i] < 0.15
            if still and start is None:
                start = i - 1
            if (not still or i == n - 1) and start is not None:
                span = (times[i - 1] - times[start]) * 1000
                if span >= 150:
                    frozen.append([round(times[start], 3), round(span)])
                start = None

    empty = [round(times[i], 3) for i in range(n) if active[i] and not heat_on[i] and not markers_on[i]]

    # Dropouts: what the map showed (heat and markers, each against its
    # threshold) collapses below a quarter of its best in the half second
    # before. A legit absence (no capsules here) is steady, a swap that leaves
    # the map bare, or heat that blinks out, is a sudden drop.
    score = heat / 0.008 + markers / 0.0022
    dropouts = []
    for i in range(1, n):
        if not active[i]:
            continue
        j = i
        while j > 0 and times[i] - times[j - 1] <= 0.5:
            j -= 1
        best = score[j:i].max() if i > j else 0
        if best >= 1.5 and score[i] < 0.25 * best:
            dropouts.append(round(times[i], 3))

    # Heat blinks: heat falls below a quarter of its recent best (with no
    # markers on the map) and comes back above half of it within a second.
    blinks = 0
    i = 1
    while i < n:
        if active[i] and not markers_on[i]:
            j = i
            while j > 0 and times[i] - times[j - 1] <= 0.5:
                j -= 1
            best = heat[j:i].max() if i > j else 0
            if best > 0.008 and heat[i] < 0.25 * best:
                k = i
                while k < n and times[k] - times[i] <= 1.0 and heat[k] < 0.5 * best:
                    k += 1
                if k < n and times[k] - times[i] <= 1.0:
                    blinks += 1
                    i = k
        i += 1

    active_s = float(sum(times[i] - times[i - 1] for i in range(1, n) if active[i - 1] and active[i]))
    result = {
        "video": path,
        "duration_s": round(float(times[-1] - times[0]), 2) if n else 0,
        "frames": n,
        "harness_strip": has_strip,
        "active_s": round(active_s, 2),
        "active_frames": int(active.sum()),
        "active_fps": round(int(active.sum()) / active_s, 1) if active_s else 0,
        "gaps_100ms": len(gaps),
        "longest_gap_ms": max([g[1] for g in gaps], default=0),
        "gaps": gaps,
        "frozen_150ms": len(frozen),
        "longest_frozen_ms": max([f[1] for f in frozen], default=0),
        "frozen": frozen,
        "empty_frames": len(empty),
        "empty_at": empty[:40],
        "dropout_frames": len(dropouts),
        "dropouts_at": dropouts[:60],
        "heat_blinks": blinks,
    }
    if frames_csv:
        with open(frames_csv, "w") as f:
            f.write("t,active,tick,heat,markers,change\n")
            for i in range(n):
                f.write(f"{times[i]:.3f},{int(active[i])},{int(tick[i])},{heat[i]:.4f},{markers[i]:.4f},{change[i]:.3f}\n")
    return result


if __name__ == "__main__":
    args = sys.argv[1:]
    csv = None
    if "--frames" in args:
        i = args.index("--frames")
        csv = args[i + 1]
        del args[i: i + 2]
    print(json.dumps(report(args[0], csv), indent=1))
