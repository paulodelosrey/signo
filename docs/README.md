# Documentation

Reference material for Signo. Nothing here is compiled into the app: the shipped
product lives entirely in `signo_app/`.

| Folder / file | What it is | Read it if you want to know |
|---|---|---|
| `lsc-grammar/` | 12 files of DBLSC grammar: chapter notes, a glossary, syntactic patterns and a cheatsheet, compiled from the corpus | Where the translator's grammar rules actually come from |
| `design-reference/` | Screen mockups produced during design, one folder per screen | How the UI was designed before it was built |

## Why these are here at all

`lsc-grammar/` and `design-reference/` are not referenced by any Dart code,
`pubspec.yaml` entry or build step. They are kept because deleting them would
remove the answer to the first question a judge asks about a sign-language app:
*where does this content actually come from?*

- `MonikLSC/` holds the interpreter's course CSV, the source `vocab.json` is
  compiled from.
- `lsc-grammar/` holds the grammar corpus the translator's rules are derived
  from.
- `design-reference/` holds the screens as they were designed.

## `design-reference/` includes directions that were rejected

Not every mockup here shipped, and the folder keeps the rejected ones on
purpose. It contains explorations that were cut — a Simon-style repetition game,
an alphabet bingo card, a camera-based exercise — along with one early concept
built around ASL rather than Colombian Sign Language.

They are here as the record of what was tried and why it did not make the cut,
not as a roadmap. `signo_app/` is the product; where the two disagree, the app
is right. The commit history carries the reasoning for each removal.
