AV-T03 (Wave 14, the owner's play notes of 2026-11-15; continue in your Wave 14 session, next after the item in hand): charge feedback as a trail of particles behind the ball.
Recommended effort: Medium–High.

First, merge `origin/claude/roguewood-build` (the UI-10 commit or later) into `codex/roguewood-build` with a merge commit.

The owner's note, on AV-T01 and AV-T02 as merged:
> "The text around the ball doesn't make much sense, the player can't see it when they're swinging the ball around. The feedback has to be visually appropriate. The sparkles are supposed to grow in density and trail as colored particles behind the ball's path to indicate spin speed and charge, not at fixed points in a circumference around the ball itself. It's the trailing particles that help indicate charge."

Do:
1. **Remove the text around the held ball:** the SWING / CURVE / FULL / NO SPIN tab (src/presentation/aim_overlay.gd), and any ring or seal that reads as fixed points around the ball. Dead Straight already says "spin is disabled" in the status line and the rule badge; under it the ball simply shows no trail.
2. **A trail of colored particles that follows the ball's path on screen** while it is held and swirled:
   - Particles are emitted where the ball has been and fade behind it.
   - Their density, trail length and brightness grow with the charge (`HeldBall.charge()`, with `spin_rate` for speed).
   - A colour step marks curve-ready (the sparkle state, `curve_ready()`) and another full charge (`full_charge()`). These are the visual moments the existing cues and vibrations mark.
   - Below a small charge, nothing shows.
3. **Both spin models** (A, the swing plus a flywheel; B, spin in place) and both spin views (depth, flat). In B the ball stays put while it spins, so the trail follows the ball's spinning rim or a short arc of its motion: your design, as long as it reads as speed and charge.
4. **Reduced motion:** no particles. The ball stays still, and the state reads through the charge meter and the existing cues only. Reduced flash: no bright bursts.
5. **Keep it cheap** on a phone and in the single-threaded web build: a bounded particle pool, no per-frame allocation.

Keep:
- **Leave the gesture and the values alone:** src/input/ (the gesture, the charge, the spin values) is the coordinator's.
- **Leave the cues alone:** `throw.charge`, `throw.curve_ready`, `throw.full_charge`, `throw.spin_tick` and their sounds and vibrations stay as they are.
- **These must keep passing:** J02 and JAVT01 (update JAVT01's captures and checks for the new look), the physics digest `75d1a3c0…`, J03 560/240/70 and J05 21060.

Paths:
- src/presentation/aim_overlay.gd and your throw-charge presentation;
- assets for it;
- tests/throw_charge_art_journey.gd (JAVT01);
- docs/art/;
- docs/art/ASSET-LEDGER.md.

tools/qa.py, the CI workflow and run_tests.gd are add-only.

When done:
- **Captures, in both views and both models:** no charge, building, curve-ready and full; a short sequence showing the trail following a swirl; and reduced motion.
- Write docs/handoffs/AV-T03.md and add it to WAVE14-CODEX.md.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
