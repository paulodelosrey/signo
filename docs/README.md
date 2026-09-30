# Documentation

Reference material for Signo. Nothing here is compiled into the app: the shipped
product lives entirely in `signo_app/`.

| Folder / file | What it is | Read it if you want to know |
|---|---|---|
| `video-script.md` | The demo video script (~90 s), under the 2-minute Shipaton limit | What the submission video says and shows |
| `lsc-grammar/` | 12 files of DBLSC grammar: chapter notes, a glossary, syntactic patterns and a cheatsheet, compiled from the corpus | Where the translator's grammar rules actually come from |
| `design-reference/` | Screen mockups generated with Stitch while designing the product, one folder per screen | How the UI was designed before it was built |

## Why these are here at all

`lsc-grammar/` and `design-reference/` are not referenced by any Dart code,
`pubspec.yaml` entry or build step. They are kept because deleting them would
delete someone's work and the reasoning behind the product:

- **The grammar corpus is a collaborator's contribution.** The LSC grammar rules
  the translator uses were derived from these notes. Shipping the app without
  them would make the linguistic basis unreproducible.
- **The mockups are the design record.** They predate the Flutter implementation
  and are why the shipped screens look the way they do. The icon's source art
  also comes from here (`design-reference/signo_app_logo/screen.png`).

Both used to sit at the repository root, where a reviewer landing on the project
saw 40 files of another tool's HTML before reaching any product code. Moving
them under `docs/` keeps the root readable without discarding anything.

## The one thing that must be tracked

`signo_app/assets/content/vocab.json` is **generated** — never hand-edit it. Run
`dart run tool/parse_vocab.dart` from `signo_app/` after changing the course CSV
or the clip manifest. Its source of truth is `MonikLSC/` at the repository root.