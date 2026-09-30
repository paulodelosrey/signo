"""Generate the demo narration with Microsoft Neural voices via edge-tts.

Runs on CPU with no GPU and no model download, which is the constraint on this
machine: there is no NVIDIA card and the integrated Intel GPU has 2 GB, so the
heavier local cloning models are not an option.

Output is one WAV per scene so a single line can be re-generated without
redoing the rest, and so each file carries its own lead-in and tail silence for
the merge to trim.
"""

import asyncio
import os
import sys

import edge_tts

OUT = r"C:\Users\paulo\Documents\Desarrollo\Signo\narration-ai"
os.makedirs(OUT, exist_ok=True)

# name, text
SCENES = [
    ("01-cold-open",
     "What if your phone could help you talk with a Deaf friend, in their own language?"),
    ("02-el-problema",
     "Across Latin America, hearing families rarely get to practice LSC, Colombian Sign Language. "
     "Courses are scarce, interpreters are busy, and most material is a static list of words."),
    ("03-ruta-aprendizaje",
     "Signo teaches LSC like a game, across five units. And every sign you can practice is a sign "
     "you can watch. One rule decides what reaches the path, so a sign with no video never gets taught."),
    ("04-diccionario",
     "The dictionary holds the whole course and states its own coverage instead of hiding the gap. "
     "Here is what plays today, and this is what does not."),
    ("05-traductor",
     "The star feature. Type any Spanish sentence and Signo turns it into an LSC sign sequence, "
     "completely offline. A grammar engine drops copulas, fronts time expressions, and reorders "
     "the phrase the way LSC actually works. Each sign plays with speed control and text to speech."),
    # The paywall's most prominent element is the "7 dias gratis" trial, so the
    # line leads with it instead of only quoting the two prices.
    ("06-premium",
     "Premium unlocks infinite hearts. Start with seven days free, then forty nine ninety nine a year, "
     "or nine ninety nine a month, powered by RevenueCat."),
    ("07-cierre",
     "Open source, M I T licensed. Built by a student with a certified interpreter and a Deaf "
     "collaborator. Signo. Speak with your hands."),
]

VOICE = sys.argv[1] if len(sys.argv) > 1 else "en-US-GuyNeural"
TAG = sys.argv[2] if len(sys.argv) > 2 else VOICE
RATE = "+4%"
# Optional third argument: regenerate only the scenes whose name contains it.
# Re-rendering one line must not touch the other six, or their timings drift.
ONLY = sys.argv[3] if len(sys.argv) > 3 else None


async def speak(name, text, voice, tag):
    path = os.path.join(OUT, f"{name}.mp3")
    comm = edge_tts.Communicate(text, voice, rate=RATE)
    await comm.save(path)
    return path


async def main():
    print(f"voz: {VOICE}")
    total = 0.0
    for name, text in SCENES:
        if ONLY and ONLY not in name:
            continue
        p = await speak(name, text, VOICE, TAG)
        kb = os.path.getsize(p) / 1024
        total += len(text.split())
        print(f"  {name:<24} {kb:6.0f} KB")
    print(f"  palabras totales: {total}")


asyncio.run(main())