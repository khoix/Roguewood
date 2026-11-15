AV-T02 (Wave 14, added by the owner, 2026-11-15; continue in your Wave 14 session): the spinning held ball's look, for the flywheel spin (E05-R5).
Recommended effort: Medium.

Merge `origin/claude/roguewood-build` (the E05-R5 commit or later) into `codex/roguewood-build` with a merge commit first. Then read:
- docs/handoffs/E05-R5.md;
- ADR 011, "Revision: the flywheel".

**What changed:** the held ball now spins on its own flywheel while the player circles.
- It can reach about 30 rad/s (nearly 5 turns a second) at full charge.
- It keeps spinning briefly after the finger stops.
- Two spin models are on the tuning page: A, the swing plus a flywheel, which is the default; and B, spin in place.

The ball is drawn turning at exactly the flywheel's spin (`HeldBall.body_angle`, `spin_rate`).

**The look:** at that speed the ball's markings strobe.
- **Readable spin:** make it read as spin at every speed, for example a motion streak or blur that grows with `abs(spin_rate)`, or markings that resolve into rings.
- **Full charge:** a clear "full" state (a glow or ring) on top of the existing curve-ready sparkle (AV-T01).
- **Both drawings:** in depth and flat spin view, for both A and B.
- **Reduced motion:** no streak and no strobe. The ball stays still, as today, and the meter and sparkle carry the state.

Keep:
- **Leave the gesture, the charge and the launch alone:** src/input/ and the spin values are the coordinator's.
- **Leave the curve cues alone:** `throw.charge`, `throw.curve_ready`, `throw.full_charge` and the new optional `throw.spin_tick`, and their vibrations.
- **These must keep passing:** JAVT01, J02 and the physics digest `75d1a3c0…`.

Paths:
- your throw-charge presentation (the JAVT01 art);
- assets for it;
- docs/art/;
- docs/art/ASSET-LEDGER.md.

tools/qa.py, the CI workflow and run_tests.gd are add-only, and every new art step has `if: matrix.shard == 'art'`.

When done:
- Extend JAVT01, or add a journey, with captures at rest, curve-ready and full spin in both views, normal and reduced motion.
- Add the item to WAVE14-CODEX.md and write docs/handoffs/AV-T02.md.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
