# DapApp Sound Assets

These 8 audio files are loaded by `TierSoundService.swift`. Missing or empty
files are a safe no-op — the app runs fine without them; you just won't hear
the sound flourish. The placeholders in this folder are all 0 bytes.

## What to add

All files are expected in `.caf` format at the paths below. Alternates
`.m4a` and `.mp3` are also supported (first match wins).

| File | Trigger | Suggested length |
|------|---------|------------------|
| `tap.caf` | DAP IT button tap | 0.1–0.2 s punchy impact |
| `tick.caf` | Countdown 3 / 2 / 1 | 0.3 s deep clock tick |
| `go.caf` | "GO!" moment | 0.5 s bright cymbal hit |
| `reveal-low.caf` | Tier 1–2 ("Ghost" / "Weak Sauce") | 1.5 s sad trombone |
| `reveal-mid.caf` | Tier 3 ("Respectable") | 0.5–1.0 s success chime |
| `reveal-fire.caf` | Tier 4 ("Crispy") | 1.0 s fire whoosh |
| `reveal-thunder.caf` | Tier 5 ("Thunderclap") | 1.5 s thunder crack |
| `reveal-quake.caf` | Tier 6 ("Earthquake") | 2.0 s cinematic boom |

## Sourcing

Pixabay (CC0, no attribution required) is the recommended source. Search
terms are listed in the project spec, e.g. "punch impact short",
"clock tick deep", "cymbal hit short", "sad trombone",
"level up chime", "fire whoosh", "thunder crack short",
"cinematic boom impact".

## Converting to .caf (macOS only)

```bash
cd DapApp/Sounds
afconvert input.mp3 tap.caf -d LEI16
# repeat for each file, matching the filenames in the table above
```

`afconvert` ships with macOS. `.caf` with `LEI16` (16-bit little-endian PCM)
decodes instantly and loops without gaps.

## Xcode wiring

`project.yml` adds `DapApp/Sounds` as a **folder reference** (not a group).
This preserves the "Sounds/" subdirectory in the bundle, which
`TierSoundService` requires via `subdirectory: "Sounds"` on the lookup.

After replacing files, regenerate the project: `xcodegen generate`.
