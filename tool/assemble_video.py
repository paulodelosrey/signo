"""Assemble the seven recorded scenes into the final demo video with the AI voice.

Why a script and not a hand-typed ffmpeg line: the scene boundaries are shared
with tool/merge_narration.py. If the two disagree by even a frame the narration
drifts against the screen, and a 77-second video with a half-second of drift looks
sloppy to a judge. Both read the same numbers, and the total is asserted against
the audio length before anything is written.

Per scene, a list of (in_point, duration) parts. Most scenes need one; scene 1
needs two because a debug build takes ~5s to cold start, far longer than the
4.32s the narration gives it, so the branded splash and the loaded UI are joined.

The recorded clips are VFR -- screenrecord only emits frames when the screen
changes, so static stretches hold 0-3 frames per second. Every segment is
normalised to a constant 30fps here; duplicated frames land exactly where nothing
was moving, which is the correct result rather than a defect.

Usage:
    python tool/assemble_video.py            # build build/signo-demo.mp4
    python tool/assemble_video.py --plan     # print the cut plan only
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "video-shots")
BUILD = os.path.join(ROOT, "build")
AUDIO = os.path.join(ROOT, "narration-ai", "narration-ai.wav")
OUT = os.path.join(BUILD, "signo-demo.mp4")

FFMPEG = shutil.which("ffmpeg") or os.path.join(
    r"C:\Users\paulo\AppData\Local\Microsoft\WinGet\Packages",
    r"Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe",
    r"ffmpeg-9.0.2-full_build\bin\ffmpeg.exe",
)
FFPROBE = os.path.join(os.path.dirname(FFMPEG), "ffprobe.exe")

W, H, FPS = 1080, 2436, 30

# scene, source, [(in_point, duration)], what the viewer should be looking at
SCENES = [
    # In-points are measured, not guessed: e1 starts on the launcher (screenrecord
    # begins before the app takes focus), the splash runs 1.1s-4.6s, and the first
    # fully rendered frame is 5.1s. Scene 1 joins the splash to the loaded UI.
    (1, "e1-raw.mp4", [(1.10, 1.40), (5.10, 2.92)],
     "branded splash, then the Aprender path"),
    (2, "e2-raw.mp4", [(1.40, 11.52)],
     "three onboarding pages, goal picker, Empezar a aprender"),
    (3, "e3-raw.mp4", [(0.20, 12.64)],
     "Unidad 1 and Unidad 2 with a sign actually playing"),
    (4, "e4-raw.mp4", [(0.00, 8.56)],
     'coverage line, search "azul", clip-less sign message'),
    (5, "e5-raw.mp4", [(0.40, 18.24)],
     "type a sentence, sequence 1/4 through 4/4"),
    (6, "e6-raw.mp4", [(0.60, 10.56)],
     "both plans, 7-day trial, Powered by RevenueCat"),
    (7, "endcard.png", [(0.00, 11.08)],
     "repo, MIT licence, Next Gen Award, honest credit"),
]


def probe(path):
    out = subprocess.run([
        FFPROBE, "-v", "error", "-show_format", "-show_streams",
        "-of", "json", path,
    ], capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def audio_duration(path):
    return float(probe(path)["format"]["duration"])


def main():
    plan_only = "--plan" in sys.argv
    total = sum(d for _, _, parts, _ in SCENES for _, d in parts)
    audio_len = audio_duration(AUDIO)

    print(f"cut plan  (video {total:.2f}s / audio {audio_len:.2f}s)")
    start = 0.0
    for num, src, parts, note in SCENES:
        path = os.path.join(SHOTS, src)
        if not os.path.exists(path):
            sys.exit(f"missing footage: {path}")
        dur = sum(d for _, d in parts)
        cuts = " + ".join(f"{i:.2f}s/{d:.2f}s" for i, d in parts)
        print(f"  {num}  {start:6.2f}-{start + dur:6.2f}  {src:<14} "
              f"[{cuts}]  {note}")
        start += dur

    if abs(total - audio_len) > 0.05:
        sys.exit(f"cut plan is {total:.2f}s but narration is {audio_len:.2f}s")
    if plan_only:
        return

    os.makedirs(BUILD, exist_ok=True)
    work = tempfile.mkdtemp(prefix="signo-asm-")
    try:
        segments = []
        for idx, (num, src, parts, _note) in enumerate(SCENES):
            seg = os.path.join(work, f"seg{num}.mp4")
            inputs = []
            for in_pt, dur in parts:
                if src.endswith(".png"):
                    # -framerate must match the chain's fps: zoompan emits exactly
                    # one output frame per input frame, so a 25 fps still yields
                    # 25/30 of the intended duration.
                    inputs += ["-framerate", str(FPS), "-loop", "1",
                               "-t", f"{dur:.3f}"]
                else:
                    inputs += ["-ss", f"{in_pt:.3f}", "-t", f"{dur:.3f}"]
                inputs += ["-i", os.path.join(SHOTS, src)]

            # Every chain ends in a labelled [v] so the map is unconditional.
            # A still card gets a slow push-in; a screen recording is left alone.
            if src.endswith(".png"):
                vf = (f"[0:v]scale={W * 2}:{H * 2},zoompan="
                      f"z='min(zoom+0.00022,1.05)':d=1:"
                      f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
                      f"fps={FPS}:s={W}x{H},setsar=1[v]")
            elif len(parts) == 1:
                vf = f"[0:v]fps={FPS},scale={W}:{H},setsar=1[v]"
            else:
                labels, concat_in = [], []
                for i in range(len(parts)):
                    labels.append(
                        f"[{i}:v]fps={FPS},scale={W}:{H},setsar=1[v{i}]")
                    concat_in.append(f"[v{i}]")
                vf = ";".join(labels) + (
                    f";{''.join(concat_in)}concat=n={len(parts)}:v=1:a=0[v]")

            subprocess.run([
                FFMPEG, "-y", "-v", "error", *inputs,
                "-filter_complex", vf, "-map", "[v]",
                "-frames:v", str(int(round(sum(d for _, d in parts) * FPS))),
                "-c:v", "libx264", "-preset", "slow", "-crf", "19",
                "-pix_fmt", "yuv420p", "-r", str(FPS),
                "-video_track_timescale", "30000",
                seg,
            ], check=True)
            want = sum(d for _, d in parts)
            got = float(probe(seg)["format"]["duration"])
            if abs(got - want) > 0.05:
                # Almost always a VFR source that ran out of frames before the
                # requested out-point, or an in-point past the end of the clip.
                sys.exit(
                    f"scene {num} ({src}) rendered {got:.2f}s, expected "
                    f"{want:.2f}s -- shorten the in-point or lengthen the take"
                )
            segments.append(seg)
            print(f"  rendered scene {num}  {got:.2f}s")

        listing = os.path.join(work, "concat.txt")
        with open(listing, "w", encoding="utf-8") as fh:
            for s in segments:
                fh.write("file '" + s.replace("\\", "/") + "'\n")

        silent = os.path.join(work, "silent.mp4")
        subprocess.run([
            FFMPEG, "-y", "-v", "error", "-f", "concat", "-safe", "0",
            "-i", listing, "-c", "copy", silent,
        ], check=True)

        subprocess.run([
            FFMPEG, "-y", "-v", "error", "-i", silent, "-i", AUDIO,
            "-map", "0:v", "-map", "1:a",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
            "-movflags", "+faststart", "-shortest", OUT,
        ], check=True)

        got = float(probe(OUT)["format"]["duration"])
        print(f"\nwrote {OUT}")
        print(f"  duration {got:.2f}s   (limit 120s: "
              f"{'OK' if got < 120 else 'OVER'})")
        if abs(got - audio_len) > 0.10:
            sys.exit(f"final is {got:.2f}s, narration is {audio_len:.2f}s")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
