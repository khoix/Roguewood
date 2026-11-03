# AV-H2-B — Clean Pickup, House Special, Front Line

State: DONE — implementation and verification complete.
Codex / codex/roguewood-build, base 96d5e22. Coordinator 0c9d915 already merged;
fetch found no newer integration work. This is the last Codex Wave 8 batch.

## Delivered

All six slots per assigned Charm: original identity art, existing uncommon/common
Charm frames, static reduced-motion identity, activation and original procedural
sound. Exact prompt/source hash and foley commands are in ASSET-LEDGER. Briefs:
docs/art/briefs/E17-D08.md. Contact journey JAVH2BC runs on CI's art shard.

- Clean Pickup: dustpan sweeps a straight path; one straight trail per committed
  roll on its eligible spare cue, held static in reduced motion.
- House Special: House chalkboard overlays the exact existing ball.house icon
  when the eligible strike's committed rolls all use House Ball.
- Front Line: three shield outlines at actual rack positions 1/2/3; only counted
  fallen positions flatten, keeping numbered circles readable. Reduced motion
  uses the final flat pose. Resolver count and actual positions remain authoritative.

The public result facts omit curved/all_house, so the read-only adapter uses the
immutable frame's committed roll records. No rules were changed to expose data.
Shared mixer/mute/effects/reduced-motion controls retained. No gameplay, saves,
League gates or House theme bindings changed. Only these three items' slots and
artwork/effects_audio flags are in scope. No Wave 9 item flags or screenshots.

## Verification

PASS: repository `qa.py unit`, `content` and `physics`; J03C09 and JAVH2BC
headless and rendered, with all three native captures visually inspected.
Headless regression PASS: J03, J05, J06, J03C01–C08, J03C10,
JAVC03A/B, JAVC04A/B/C, J22L01ART, J21R03/R04, J11ART, J12V08,
J19A16, JAVC07AC/BC and JAVH1AC/BC/JAVH2AC. J03C06/C07 retain the
AV-C06/C07 native checks. J03 remains 560/240/70; J05 remains 21060.
Physics digest: `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
Catalogue diff is limited to these three items' six slots and two art flags.
qa.py, CI and J03C09 additions are add-only; run_tests.gd is unchanged.

J03C09 additions preserve real purchases/throws and earlier AV-H2-A checks.
New native assertions/captures cover two straight rolls on a spare, an all-House
strike, and shields matching counted positions and count. Pure projection checks
cover 0/1/2/3 front positions, supplementing the native frame. Skipped/muted cue
fixtures stay silent. JAVH2BC contact inspected at 180px/48px. No phone or
subjective listening gate claimed. Logs: artifacts/av-h2-b/validation. Native
captures: artifacts/e18-c09/rendered/charm_{clean_pickup,house_special,front_line}_cue.png.

Runtime was restored after /tmp cleanup: pinned Godot 4.5.2 archive verified
against tools/godot-downloads.sha512, extracted under /tmp/roguewood-godot.
Debian xvfb_21.1.16-1.3+deb13u4 extracted under /tmp/roguewood-xvfb/root;
Xvfb :99 uses 1280x1024x24 and -nolisten tcp. No system/project settings changed.
Run repository qa.py directly with these runtime paths; they are temporary.

## Resume exactly here

AV-H2-B is delivered with this commit; Codex's four Wave 8 batches are DONE.
Coordinator can merge codex/roguewood-build into claude/roguewood-build and
owns integration CI, central progress and wave closure. No Codex PR to main.
Do not begin Wave 9 under this assignment. Next planned art: AV-H3/AV-H4,
Medium by default, High for complex or counted effects, subject to new claims.
