# Codex brief — UI-A9, the alley screen's celebrations (Wave 14)

## The owner's request (2026-11-19)
> "brief celebratory animations in that zoom-in window for strikes and spares. I want it to be reminiscent of the cheesy animations that play on the screen at bowling alleys, but automatically aligned with each league and the design theme of the game in general."

> "include an animation for defeating a boss. The animation has to have the feel of it being played on a CRT with subtle scan lines."

## Who does what
- **Claude (UI-20, spec: docs/handoffs/UI-20.md):**
  - the alley screen: the window, triggers, timing, skip, queue, stings playback, fallbacks and tests;
  - a placeholder scene per event and a baseline CRT shader, so the system works before your art lands.
- **You (UI-A9):** the House and Neon celebrations (three each), their stings and the final CRT look. You also write down the standard the later Leagues follow.
- **Order:** start after the items already in your Wave 14 queue (AV-N4, AV-N5, UI-A6), once UI-20 is merged into `claude/roguewood-build`.

## Scope
**Six animations:**

| League | Strike (≈1.8 s) | Spare (≈1.6 s) | Boss defeated (≈3 s) |
|---|---|---|---|
| House | ✓ | ✓ | ✓ |
| Neon | ✓ | ✓ | ✓ |

Plus:
- **Six stings:** one short sound per event and League.
- **The CRT treatment:** you take over assets/ui/alley_screen/crt.gdshader from Claude's baseline.
- **Later Leagues:** Salvage, Royal, Spectral and Foundry get theirs with their League themes (E22-L03-ART onward). Write the standard for them into your handoff.

## The feel
**Cheesy alley-screen energy, in Roguewood's style.** Think of the overhead screens at a bowling alley: big bouncing "STRIKE!" letters, pins that fly off with silly faces, a ball that takes a bow, starbursts and confetti. Make it **reminiscent, never copied.**
- No characters, gags or layouts from real bowling-alley systems or other games.
- Everything original, recorded in docs/art/ASSET-LEDGER.md as before.

**Each League's own voice:** the same three beats, in the League's shapes, palette and humour. For example (Codex owns the art direction):
- **House:** a warm, old scoreboard. Wood-and-brass lettering, tumbling pins with faces, a modest confetti burst.
- **Neon:** laser outlines, glowing tubes that light letter by letter, and a soft colour sweep (no hard strobe).

**The boss win is the big one.**
- The rival's own portrait (assets/rivals/, by `rival_id`) gets a playful, never cruel, comeuppance: knocked over like a pin, swept away, or the lights going out on their sign. Then "[Rival] defeated!" or a League-flavoured line.
- It should feel earned and a step above a strike.
- The rival's name comes from `context`; never bake names into the art. The Championship (Division 8) may add a small extra flourish.

**The CRT look:**
- the same for every celebration, so all of them feel like the alley's overhead TV;
- subtle scanlines that never hurt readability;
- a slight barrel curve and a soft vignette;
- a gentle phosphor glow on bright shapes;
- optionally a quick power-on at the start and power-off at the end.

The owner asked for "subtle scan lines": keep them clearly visible but quiet.

## The technical contract (from UI-20)
**The canvas:** each scene is a `Control` at **252 × 90** pixels (2.8 : 1). It is rendered in its own SubViewport at that size, scaled with nearest-neighbour filtering into the window, under the CRT shader. Author pixel art for that canvas.

**The script provides:**
- `play(context: Dictionary)`
- `signal finished` (once, at the natural end)
- `duration() -> float` (within the lengths above)
- `skip()` (to the end, then `finished`)

**`context`** carries:
- `event`, `league_id`, `division`, `championship`;
- `rival_name`, `rival_id`, `rival_color` (boss only);
- `reduced_motion`, `reduced_flash`.

**Scenes must not:**
- handle input (the alley screen owns taps);
- play audio (the alley screen plays the sting);
- read game state beyond `context`.

**The manifest:** add to each League theme's manifest (assets/leagues/<league>/manifest.json):
- `"celebrations": {"strike": …, "spare": …, "boss_defeated": …}` (scene paths);
- `"celebration_sounds": {"strike": …, "spare": …, "boss_defeated": …}` (audio paths).

**Hooks:** if the design needs one (for example the score, the frame number, or a "turkey" for three strikes in a row), ask for it in your handoff. Claude adds it to `context`.

## Accessibility (required)
- **Reduced Motion:** a still card per event (the title art in the League's style), held for the same length. No movement, and no power-on or power-off.
- **Reduced Flash:** no flicker, no rapid brightness swings, no strobe. In every mode, nothing flashes faster than 3 times a second.
- **Readability:** the title words stay readable on a phone at portrait size through the CRT effect.

## Performance
The Web build on phones (Compatibility renderer, single-threaded). Keep:
- particle counts small;
- the CRT shader cheap (one pass);
- the SubViewport at 252 × 90.

Record the frame time during each celebration against an ordinary roll.

## Evidence
- **Captures:** native captures of all six, portrait and landscape, mid-animation and at their peak frame. Also the Reduced Motion still cards. Use UI-20's journeys or a UI-A9 art journey.
- **Checks:** `unit`, J03, J22L01, J22L02 and their art journeys, and `web`. The physics digest stays `75d1a3c0…` (celebrations are cosmetic).
- **Handoff:**
  - the frame times;
  - the asset ledger entries;
  - the standard for the later Leagues (beats, lengths, CRT settings, what changes per League).
