# Agent task handoff — AV-UI1, the final button sounds (owner, 2026-11-24)

## Assignment
- **Owner:** Claude. The owner moved AV-UI1 from Codex on 2026-11-24 while Codex is out ("Yes, please do"). The owner reviews in play.
- **State:** DONE (implementation and checks). Not listened to by Claude; not tried on a phone.
- **Brief:** handoffs/UI-12.md, "Codex brief: the final UI sound set".
- **Paths:** `tools/author_ui_sounds.py`; `assets/audio/ui_{tap,select,back}.wav` (replaced at the same paths) and `ui_{tap,select,back}.neon.wav` (new); `src/presentation/ui_sounds.gd`; tests `tests/ui_sounds_test.gd` (unit), `tests/clubhouse_journey.gd` (J11), `tests/neon_celebration_boss_journey.gd` (JUIA9NB).

## The sounds
- **House (everywhere by default):**
  - tap: a light, dry wooden knock (two wood modes and a felt thump), 45 ms;
  - select: brighter, with a small brass ting, 40 ms;
  - back: lower and softer, the pitch easing down, 65 ms.
- **Neon (the brief's optional per-League set):** pulse-wave blips.
  - tap: a short blip with a quick pitch drop, 40 ms;
  - select: two rising blips, 50 ms;
  - back: one darker, falling blip, 60 ms.
- **Loudness:** all six sit at UI-12's loudness (-25 dBFS RMS, peaks -9 to -14 dBFS), under the foley; the game still plays them at 0.8 of the effects level.

## The hook
- `UiSounds.league()` is the League of the match in play, read from the game's lab while it is in the tree.
- During a Neon match, buttons take Neon's sounds. The Clubhouse and menus (no match) and any League without its own set keep the House's (`sound_for`).

## Checks
- **`unit`** (`ui_sounds_test.gd`):
  - each kind has a House sound;
  - Neon has its own three;
  - other Leagues fall back to the House's;
  - every source file is 30–80 ms and peaks at or under -6.4 dBFS.
- **J11** (both modes): the Clubhouse's buttons take the House sounds; its existing tap, select and back and Mute checks pass.
- **JUIA9NB:** in every Division of the Neon League, the buttons pressed make Neon's sounds.
- **Also PASS:** J05, J22L01, `content`.
