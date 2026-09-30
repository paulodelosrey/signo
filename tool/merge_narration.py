"""Assemble the demo narration into one WAV on a fixed slot timeline.

Why this exists: the scene timings are the contract between the voice track and
the screen recording. They were originally produced by an ad-hoc ffmpeg command,
so nothing recorded the boundaries and re-rendering one scene silently shifted
every scene after it. Here the boundaries live in SLOT, they are asserted against
the rendered output, and one scene can be re-rendered without moving the others.

The concat demuxer is used, not the `concat` filter: every input here is already
pcm_s16le / 48 kHz / mono, which is exactly the case the demuxer is for, and the
filter-graph form is what previously failed with "Filter not found".

Usage:
    python tool/merge_narration.py            # rebuild from the 7 scene mp3s
    python tool/merge_narration.py --check    # verify only, write nothing
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "narration-ai")
FINAL = os.path.join(SRC, "narration-ai.wav")

FFMPEG_CANDIDATES = [
    r"C:\Users\paulo\AppData\Local\Microsoft\WinGet\Packages"
    r"\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe",
]

RATE = 48000
CHANNELS = 1
SAMPLE_FMT = "pcm_s16le"
# Integrated loudness target, matching what the delivered narration measured.
LOUDNESS = "loudnorm=I=-16:TP=-1.5:LRA=11"

# name, start, end -- the authoritative scene boundaries, in seconds.
# Every scene is rendered to exactly (end - start); anything longer is trimmed and
# anything shorter is padded with silence, so a re-render cannot move the scenes
# that follow it. Re-check these against the voice track before every re-record.
SLOT = [
    ("01-cold-open",      0.00,  4.32),
    ("02-el-problema",    4.32, 15.84),
    ("03-ruta-aprendizaje", 15.84, 28.48),
    ("04-diccionario",   28.48, 37.04),
    ("05-traductor",     37.04, 55.28),
    ("06-premium",       55.28, 65.84),
    ("07-cierre",        65.84, 76.92),
]


def ffmpeg():
    for c in FFMPEG_CANDIDATES:
        if os.path.exists(c):
            return c
    found = shutil.which("ffmpeg")
    if not found:
        sys.exit("ffmpeg not found")
    return found


def ffprobe():
    return os.path.join(os.path.dirname(ffmpeg()), "ffprobe.exe")


def samples_in(path):
    """Exact sample count of a PCM wav, read from the stream time base.

    Comparing float seconds lost this: `atrim` in seconds rounds, and a slot can
    come out a few hundredths short, which is enough to clip a word. Duration_ts
    on a pcm stream is the sample count, so assert on that instead.
    """
    out = subprocess.run([
        ffprobe(), "-v", "error", "-select_streams", "a:0",
        "-show_entries", "stream=duration_ts,time_base",
        "-of", "json", path,
    ], capture_output=True, text=True, check=True).stdout
    # JSON, not csv: ffprobe emits csv fields in the stream's own order, not the
    # order they were requested, so positional parsing silently swaps them.
    stream = json.loads(out)["streams"][0]
    num, den = (int(x) for x in stream["time_base"].split("/"))
    if num != 1:
        sys.exit(f"unexpected time_base {stream['time_base']}, want 1/sample_rate")
    # time_base is 1/sample_rate, so duration_ts is already the sample count.
    return int(stream["duration_ts"])


def duration(path):
    out = subprocess.run(
        [ffmpeg(), "-hide_banner", "-i", path],
        capture_output=True, text=True, errors="replace",
    ).stderr
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("Duration:"):
            hms = line.split("Duration:")[1].split(",")[0].strip()
            h, m, s = hms.split(":")
            return int(h) * 3600 + int(m) * 60 + float(s)
    return None


def main():
    check_only = "--check" in sys.argv
    exe = ffmpeg()
    total = SLOT[-1][2]

    print(f"slot timeline ({total:.2f}s)")
    for name, start, end in SLOT:
        src = os.path.join(SRC, f"{name}.mp3")
        if not os.path.exists(src):
            sys.exit(f"missing scene audio: {src}")
        d = duration(src)
        span = end - start
        flag = "pad" if d < span else ("trim" if d > span else "exact")
        print(f"  {name:<22} {start:6.2f}-{end:6.2f}  slot {span:6.2f}s  "
              f"src {d:6.3f}s  {flag}")

    if check_only:
        return

    work = tempfile.mkdtemp(prefix="signo-narr-")
    try:
        parts = []
        for i, (name, start, end) in enumerate(SLOT):
            span = end - start
            want = int(round(span * RATE))
            src = os.path.join(SRC, f"{name}.mp3")
            part = os.path.join(work, f"{i:02d}.wav")
            # apad then atrim by sample count: pads short scenes with silence and
            # trims long ones, so every part is exactly its slot to the sample.
            subprocess.run([
                exe, "-y", "-v", "error", "-i", src,
                # aresample must sit between loudnorm and atrim: loudnorm runs
                # internally at 192 kHz, so an end_sample placed before a plain
                # `-ar 48000` counts samples at 192 kHz and yields a quarter-length
                # scene. Pin the rate inside the graph, then trim to the sample.
                "-af", (f"{LOUDNESS},aresample={RATE},aformat=channel_layouts=mono,"
                        f"apad,atrim=end_sample={want},asetpts=N/SR/TB"),
                "-ar", str(RATE), "-ac", str(CHANNELS),
                "-c:a", SAMPLE_FMT, part,
            ], check=True)
            got = samples_in(part)
            if got != want:
                sys.exit(
                    f"slot {name} rendered {got} samples "
                    f"({got / RATE:.3f}s), expected {want} ({span:.3f}s)"
                )
            parts.append(part)

        listing = os.path.join(work, "concat.txt")
        with open(listing, "w", encoding="utf-8") as fh:
            for p in parts:
                # The concat demuxer does not use shell quoting, and on Windows it
                # cannot open a path containing backslashes. Forward slashes only.
                fh.write("file '" + p.replace("\\", "/") + "'\n")

        raw = os.path.join(work, "narration-ai.wav")
        subprocess.run([
            exe, "-y", "-v", "error", "-f", "concat", "-safe", "0",
            "-i", listing, "-c", "copy", raw,
        ], check=True)

        got = samples_in(raw)
        want = int(round(total * RATE))
        if got != want:
            sys.exit(f"merged track is {got} samples, expected {want}")

        shutil.copyfile(raw, FINAL)
        print(f"\nwrote {FINAL} ({total:.2f}s)")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
