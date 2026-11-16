# Wave 14 Codex checkpoint

Status: IN_PROGRESS. Branch: codex/roguewood-build (2026-11-15).

Coordinator be1d045 was merged with merge commit c9ecd381. Includes E05-R5
and UI-9. No rebase, force-push, main push or PR. Initial synchronization
checkpoint: 2b3653e. The owner's session prompt replaces codex-wave14.md;
per-item briefs still apply.

## Items

- AV-T02: DONE; implementation and verification recorded in AV-T02.md.
- AV-T03: DONE; verification and 85 captures in AV-T03.md. Supersedes AV-T02 held-ball visuals.
- UI-A7: DONE; local hall motion, pixel 3D ball, native/web checks and loader review in UI-A7.md.
- AV-N3, AV-N4, AV-N5, UI-A6: not started. No DONE handoffs to skip.
- Salvage art stays outside Wave 14.

## Owner capture index

AV-T03: 85 ignored captures in artifacts/av-t01/rendered/ replace the old
AV-T02 captures. Review depth_normal_swirl_130/135/140.png, then the
model2_flat_normal sequence and depth_motion_full.png. All models/views,
charge stages and accessibility modes: AV-T03.md. No captures committed.

UI-A7: artifacts/ui-a7/{portrait,landscape}/motion_000..036.png, reduced_early/late,
loader/half.png and complete.png, and both 31-capture phone tours. Full index: UI-A7.md.

## Exact resume step

Continue with AV-N3 (High): read E17-D14, E18-C17, AV-N1/AV-N2 and
WAVE13-CODEX. List each ID/slot, provenance plan and native captures before
producing art. Six items: Dry Side, Lane Reader, Hook Shot, Line Call,
Bounce Back, Straight Money. Preserve J03C17's actual 34-ft side reading,
lane, stretched aim guide, and Bumper Guard rescue payout. Follow item limits
and write AV-N3.md; push/verify before AV-N4, AV-N5 and UI-A6 in that order.

## Validation environment

Installed pinned Godot 4.5.2 in /tmp/godot452/ (outside source). Set GODOT_BIN
explicitly. XDG_CONFIG_HOME=/tmp/roguewood-config,
XDG_CACHE_HOME=/tmp/roguewood-cache, XDG_DATA_HOME=/tmp/roguewood-data.
Rendered runs use isolated Xorg dummy display :98 (MIT-SHM disabled) configured by
/tmp/roguewood-xorg.conf. Engine/display may need reinstalling after session
reset. The initially installed 4.6.3 was not used for passing checks.
Local logs: /tmp/t03-*.log (prior checkpoint /tmp/w14-*.log); durable results in the item handoff. Full-wave
regression matrix remains for subsequent items/integration.

UI-A7 environment: Xorg :96; matching Playwright browser in /tmp/a7-browsers,
web templates installed under the temporary XDG data directory. Logs /tmp/a7-*.log.

UI-A7 owner correction: restored original illustrated ball design and reflective
finish at larger scale. Latest captures are artifacts/ui-a7-revision/
final-{portrait,landscape}/; see UI-A7.md's owner-correction section. Remaining
item order is unchanged.
