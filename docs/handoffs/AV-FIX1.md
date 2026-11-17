# AV-FIX1 — Spare Jar transparency checkpoint

State: IN_PROGRESS. Timed High-effort window, 2026-11-17, stop at 22:26 UTC.
Coordinator 5b782e1 merged by 6a2f4f5. Additive ledger conflict resolved by keeping
both sections. Seven other cards were already matted by the coordinator.

Spare Jar now uses a regenerated RGBA source, preserving its brass rim, green
glass and two copper coins. An initial pass added unwanted external haze; a
second generation pass removed it. Original source sheet remains unchanged.
Final PNG is copied without pixel edits; card, icon and reduced views share an
AtlasTexture region. In-play counted-jar presentation uses its existing icon
hook; no catalogue, effects, sound or rule changes. Exact prompts, SHA and alpha
samples are in the brief/ledger and artifacts/wave14/av-fix1/alpha-audit.json.
The mouth is transparent, central glass alpha is 4/255 and upper background
sample is zero. Spare Jar is removed from KNOWN_OPAQUE in the existing guard.

## Evidence so far

Unit, content and JAVH3BC headless/rendered pass. The new contact sheet was
visually reviewed: no dark rectangle or surrounding haze, including small icons.
J11 headless/rendered and J03C10 headless pass, including the original counted-jar
purchase/growth/sell/rebuy assertions. The native Binder capture tool passes in
both modes (ROGUEWOOD_FIX1_BINDER_OK); portrait and landscape after captures
were visually reviewed, with clear glass over the preview panel and no plate.
Pinned Godot 4.5.2, Xorg :90 with MIT-SHM disabled; temporary XDG directories.

Before contact images: artifacts/av-fix1/before/.
After contact images: artifacts/av-h3-b/contact/rendered/.
After native Binder: artifacts/av-fix1/binder/rendered/binder_portrait.png and
binder_landscape.png.
Tests/logs: artifacts/wave14/av-fix1/ and /tmp/fix1-c10-headless.log.
The capture tool tools/capture_spare_jar_binder.gd drives the real Binder through
native controls without Career fixtures. Use --artifact-dir, --save-dir and
--content=house with the pinned engine and --fixed-fps 60. Captures are ignored,
never committed. No phone hardware or full-matrix claim.

## Exact resume

Run J03C10 rendered and collect the remaining native shop/Binder before and
after evidence in both orientations required by the brief. Binder after captures
are complete; shop before/after and Binder before captures remain. The retained original
source permits a labelled before-art specimen if a baseline capture is needed;
do not forge gameplay or Career state. Review the coordinator's seven mattes as
needed; AV-H4 checks were already run by the coordinator, not claimed here.
Register any permanent new art journey add-only and gate new CI steps to art.
Then run the remaining affected checks from the brief, mark AV-FIX1 DONE, update
WAVE14-CODEX.md and commit/push/verify. Until then this is a partial correction,
not a completed AV-FIX1 delivery. No Wave 15 work.
