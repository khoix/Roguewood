# UI-A6 — Manifest pin decks and the House finish

State: DONE — implementation and verification (2026-11-17). Prescribed effort: Medium.
Branch: codex/roguewood-build; starting checkpoint 44c7187. Fetch and no-ff merge
of origin/claude/roguewood-build reported already up to date at 8bafa27, already
included through 0cbd9a4. No rebase, force-push, main push or PR.

## Implementation

House and Neon manifests name a top-level `pin_deck` material path. The hook
loads that material and dresses only the existing two kickback meshes and
cushion mesh. Missing entries preserve plain walls. The generic `pin_deck`
metadata records the asset path; the old Neon marker remains for its existing
journey contract. Neon's material and shader are byte-identical.

House uses original static walnut grain, dark recessed panels, brass rails and
diamond inlays. Its unshaded shader changes neither lighting nor geometry.
Bodies, collision shapes, physics materials and lane-condition surfaces are
untouched. No motion or flashes, including with reduced settings. Provenance:
docs/art/ui/UI-A6.md and ASSET-LEDGER.md. No external art or audio sources.

The owner explicitly authorized the existing art unit-test correction. Before
checking the missing-entry fallback, it resets the material and clears both
markers, then asserts that neither material nor markers changed. Existing
physical-body checks remain.

JUIA6 extends the full native House League journey without replacing its real
play, scoring assertions, save/resume or title checks. Every match checks three
House finish bindings and no Neon marker. Eight opener captures plus the
Championship cover all nine stages. Division 2 feature, Division 3 boss and the
Championship add portrait/landscape views and a normal-camera roll capture;
reduced-motion presentation is used for the other stages.

## Verification and capture index

All 35 targeted checks pass. Pinned Godot 4.5.2, isolated Xorg :90, MIT-SHM off,
LP_NUM_THREADS=2, temporary XDG directories. Results/logs:
artifacts/wave14/ui-a6/results.jsonl. Unit/content/physics pass; digest:
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.

Passing targeted journeys: JUIA6, J22L01, J22L02, J22L01ART, J22L02ART,
J22L02LIVEART, J06, J11, J11ART, J03, J05, J02, JAVT01, J08, JUIA1 and JUIA2,
headless and rendered. All success markers were verified after the worker completed.
J03 remains 560/240/70 and J05 remains 21060 in both modes.

All 21 House captures were reviewed, including all nine stages and the three
selected portrait/landscape/roll views. Upper wall faces are dressed; the pit
floor is recessed and mostly hidden, so no additional mesh changes were needed.
Fresh normal/reduced Neon comparison captures were reviewed; its finish is
unchanged. Scope audit and validation-summary.json are beside the logs.

These are local Linux checks with dummy audio, not phone hardware or full CI/Web
validation. The full art-shard matrix last ran at AV-N5; it was not repeated in
full for UI-A6. Coordinator integration and wave closure remain separate.

21 native captures in artifacts/ui-a6/rendered/, never committed:
- deck_d01_opener through deck_d08_opener; deck_d08_boss.
- deck_d02_feature_{portrait,landscape,roll}.
- deck_d03_boss_{portrait,landscape,roll}.
- deck_d08_boss_{portrait,landscape,roll}.
- inherited j22_champion, j22_title, j22_tournament.
Neon comparison: artifacts/e22-l02-art/live/rendered/live_pin_deck_{normal,reduced}.png.

## Exact resume

UI-A6 is ready for coordinator integration. The completion commit and verified
remote SHA are reported with this checkpoint. All assigned Codex Wave 14 items
are DONE. Stop here; no next Codex milestone or effort is assigned in this wave.
No Salvage Wave 15 art or proposed AV-UI1 work. The coordinator owns central
progress, integration checks and wave closure. No external message is sent.

## Coordinator merge re-verification — 2026-11-23

Coordinator 329447e merged by 489c007. The existing pin-deck hook/materials
remain unchanged. The art journey now presses Resume after closing Throw
Settings, matching the coordinator's menu flow. Unit/content, J22L01/J22L02,
JUIA6 and J22L02LIVEART pass (journeys headless/rendered). Fresh captures are
available in the original directories; the 2026-11-17 full deck visual review
remains recorded above. Physics digest remains 75d1a3c0…; BAL-1 values are now
J03 600/260/70 and J05 match 2 25920, passing both modes. Results:
artifacts/wave14/resume-20261123/. Full push CI is separate. UI-A9-H (High)
is now assigned next, after the AV-N4 Comet rotation blocker; this supersedes
the historical no-next-milestone instruction above.
