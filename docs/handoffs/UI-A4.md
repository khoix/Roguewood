# UI-A4 — Roguewood brand art

State: DONE (implementation and verification).
Medium effort. Branch codex/roguewood-build, coordinator 254a921 merged at
81cda95. Added to Wave 13 by the repository's owner-directed claim.

## Delivered

Original transparent brass/wood ROGUEWOOD logo, a simple petrol bowling-ball app
icon and an opaque wordmark splash on exact #0b1116. No subtitle. The existing
one-action title screen uses the logo through UI-7's hook. The authored House
night hall and rolling ball remain; optional new title key art was not needed.

Fixed paths: assets/brand/logo.png (2172×724 RGBA), icon.png (512×512 opaque,
111430 bytes), splash.png (720×560 opaque RGB). Both original image-generation
sources are retained unchanged. The requested author_brand.py production exporter
sizes the icon, bounds its palette and assembles the splash; it no longer makes
provisional images. Exact prompts, source/export hashes and choices are recorded
in docs/art/ui/UI-A4.md and docs/art/ASSET-LEDGER.md.

No src/, tests, project.godot or export_presets.cfg changes for this batch.
No placement, background-colour or other coordinator hook request.

## Verification / review

Before replacement: J01 rendered and JW01 web PASS; captures preserved under
artifacts/wave13/ui-a4/before/. Final unit/content/physics, J01 headless/rendered
and JW01 web PASS. The web check verifies the exact 720×560 splash/night background,
favicon, 180px apple-touch-icon, title tap, native mouse flick, saved roll,
IndexedDB reload and Continue, with no script errors. The exported full-size
favicon is 118732 bytes, below 150 KB (source icon 111430 bytes).

Both existing phone tours completed all 30 captures at 360×780 and 780×360;
title portrait/landscape and actual 180/32/16 icon sizes were inspected. The
landscape tour emitted a one-resource/ObjectDB shutdown warning after its success
marker and exit 0; the portrait tour and strict J01/JW01 checks are clean. This
capture-tool teardown warning is recorded for the coordinator, not claimed as a
clean assertion-based test or attributed to a specific production cause. No code
outside the UI-A4 claim was changed to suppress it.

The first final web run exposed the fixed 720×560 splash contract and CPU-contention
slow-flick cancellation. The splash export preserves that contract; the final
isolated browser rerun passes without weakening tests. Original failure log:
artifacts/wave13/ui-a4/final/web-initial-failure.log. Final results:
artifacts/wave13/ui-a4/final/complete-results.json. Final 32-colour production
exports regenerate byte-identically; exact hashes are in the asset ledger.

Owner capture index (local ignored outputs, never committed):

- artifacts/e03/rendered/title.png: the actual native title.
- artifacts/e26-w01/headless/web_loading.png and web_title.png: the real loader
  and title in Chromium, including exported favicon/apple-touch-icon checks.
- artifacts/ui-a4/tour-portrait/01_title.png and tour-landscape/01_title.png:
  existing phone-tour tool at 360×780, rotated for landscape.
- artifacts/ui-a4/brand/icon_sizes.png, icon_180.png, icon_32.png, icon_16.png:
  actual-size icon review (regenerate with author_brand.py --previews).

Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, Playwright 1.63.0 Chromium,
Xorg :100 without MIT-SHM, Dummy audio. No physical iPhone installation, device
performance or browser-tab visual trial claimed. WAVE13-CODEX.md is the wave
index. The coordinator owns central state and integration to main. Optional
capture-tool follow-up: inspect the landscape tour shutdown warning using the
logged command; it did not prevent any required capture or strict journey.
