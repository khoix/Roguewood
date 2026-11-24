# Agent task handoff — UI-A9-N preview, three Neon celebrations (owner, 2026-11-24)

## Assignment
- **Owner:** Claude, at the owner's request while Codex is out ("Which of its tasks are you able to fulfill? Do a test demo for me to preview").
- **State:** DONE as a preview; it is not UI-A9-N. Nothing loads it: the scenes are in no League manifest, and the game is unchanged.
- **Branch:** `claude/roguewood-build`.
- **Paths:** `assets/ui/alley_screen/neon/` (neon_kit.gd, celebration.gd, strike_laser_sweep.tscn, spare_bank_shot.tscn, boss_laser_lena_lights_out.tscn).

## What it is
- Three 252 x 90 code-drawn scenes on the House contract (`play(context)`, `skip()`, `duration()`, `finished`; reduced motion holds the final tableau):
  - **Laser Sweep** (strike, 1.8 s): neon pins scatter under a sweeping ball, "STRIKE! / PERFECT SWEEP".
  - **Bank Shot** (spare, 1.6 s): the ball rebounds off the top rail onto the last pin, "SPARE! / BANK SHOT".
  - **Lights Out** (Laser Lena defeated, 3.0 s): her defeated portrait (`RivalArt`), her laser line breaking, a "DEFEATED!" sign buzzing on, "LINE BROKEN".
- `neon_kit.gd`: palette (night, grid, magenta, cyan, violet, gold), glow tubes, a perspective grid stage, neon-outline pins and ball, sparks.
- No sound.

## For Codex (UI-A9-N, Wave 15)
Adopt, restyle or replace these; they claim no IDs in the Neon manifest. The owner decides whether Claude builds the full set of 18 while Codex is out.

## Checks
- Rendered frame by frame in a 252 x 90 view (script in the session scratchpad, not committed); GIFs sent to the owner.
- `unit`, `content`: PASS with the files present.
