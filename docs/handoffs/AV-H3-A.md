# AV-H3-A — Spare Ball, Workhorse, Oak Pin

State: DONE (implementation and native verification).
Branch: `codex/roguewood-build`; base merge `ad8b948`, incorporating Claude
`1f1f34d` (latest E26-W01 hosting decisions). UI-A1-B is already on this branch.
No main merge or Wave 9 closure is claimed.

## Delivered

Seven resource slots and both `artwork`/`effects_audio` flags for only:
`ball.spare_ball`, `ball.workhorse`, `pin.oak`.

- Spare Ball: plain petrol plastic, straight ivory stripe, original identity,
  common frame, static reduced image, eligible-spare parallel-guide activation
  and short plastic knock. World-oriented material stripe stays fixed while the
  body rotates; translation is removed from stripe coordinates. Existing spin
  response is untouched.
- Workhorse: scuffed oxblood resin and worn shield. Exactly one tally per
  authoritative resolver `count`, with committed roll identity carried alongside.
  Count never depends on animation age or contacts. +2 Value per counted pin
  stays explicit in the native explanation. Original low resin knock.
- Oak Pin: tight dark grain, walnut neck rings, original acorn identity. An
  actual rigid-body contact starts a two-second damped visual rock, max 0.035 rad.
  It moves only a child mesh, adds no collision objects, and never writes parent
  transform/velocity/mass. Reduced motion/flash suppresses the cosmetic rock.
  Fallen activation has a low settling arc and original hardwood knock.

Source/brief: `docs/art/briefs/E17-D09.md`, retained original generation prompt,
`assets/items/d09/`, and ASSET-LEDGER provenance/hash. No external image, sample,
brand or licence-dependent audio was introduced. Generated source is unchanged;
AtlasTexture views provide card, icon and reduced identities. Original common
frame style matches today's card UI. No production UI scripts, rules, physics,
input, project settings, export presets or House League bindings changed.

## Verification

Pinned Godot 4.5.2, Linux Compatibility / Mesa llvmpipe:

| Check | Result |
|---|---|
| `qa.py unit` | PASS, including new projection/negative-strike checks |
| `qa.py content` | PASS after both flags were enabled |
| `qa.py physics` | PASS; digest `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f` |
| J03C10 headless and rendered | PASS; unchanged banks 660/750/78/612 and open income $2 |
| JAVH3AC headless and rendered | PASS; card/icon/reduced identities, normal/reduced cue specimens, sound resources |
| J03, J05 headless | PASS; 560/240/70 and 21060 unchanged |
| J03C08, J03C09 headless | PASS; prior House presentation preserved |
| Scope and whitespace | Catalogue diff only the three assigned asset sets/two flags; diff check PASS |

Native J03C10 still buys and plays all six D09 items through actual controls.
It additionally checks real armed-ball bindings, all three native resolver cues
and audio dispatch, Workhorse count/amount, eligible Spare category, Oak identity,
normal impact follow-through and reduced cue mode. Normal mode is selected
through Options for the Workhorse/Oak strike; reduced mode for the Spare Ball.
The original journey assertions and captures remain intact; additions are additive.
Completion flags were false for initial native checks and enabled afterwards.

Captured and inspected:
- `artifacts/av-h3-a/contact/rendered/contact.png`, `motion.png`.
- `artifacts/e18-c10/rendered/ball_workhorse_armed.png`, `ball_workhorse_roll.png`,
  `ball_workhorse_cue.png`.
- `ball_spare_ball_armed.png`, `ball_spare_ball_roll.png`, `ball_spare_ball_cue.png`
  in the same native folder.
- `oak_rock.png`, `pin_oak_cue.png`, plus original five C10 captures.
Logs copied under `artifacts/av-h3-a/validation/`; all are ignored output, never
committed screenshots. Shared mixer/mute/skip controls remain unchanged.
Subjective listening and physical-phone certification are not claimed.

The full Wave 9 headless/rendered regression matrix is not claimed here. It
remains the closing task after AV-H3-B; existing CI steps were preserved.
New JAVH3AC runs only in the art shard; upload folder is in the existing path list.
`qa.py`, `run_tests.gd`, workflow and J03C10 changes are add-only.

## Hand-off / resume exactly here

Ready for Claude to inspect/integrate as AV-H3-A. No PR to main. AV-H3-B's items
and E17-D10's five flags remain unchanged. No AV-T01 or Wave 10 work started.

1. Fetch origin, verify this pushed checkpoint and merge newer Claude work with
   a merge commit if needed; stay on `codex/roguewood-build`.
2. Start **AV-H3-B**, High recommended: Tin Pin, Spare Jar, Consolation Prize.
   Read E18-C10, E17-D09 landed presentation needs and this extended J03C10.
   Spare Jar must show persistent count and add its new pin only after bank;
   counts/conditions must come from authoritative events/facts. Tin needs its
   surviving-frame coin, Consolation its open-frame ribbon.
3. Complete briefs, identity/in-play (Tin), activation/sound, native checks,
   then both flags for those three only. Preserve the A checks and captures.
4. Run the full required Wave 9 matrix, write AV-H3-B.md and WAVE9-CODEX.md.
   Include all ten UI-A1 owner-review captures from UI-A1-B.md. Push and verify
   remote SHA/clean tree. Wave 9 is still open at this batch checkpoint.
