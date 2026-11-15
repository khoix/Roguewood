# UI-A4 — Roguewood brand art

Wave 13, Medium effort. Replaces UI-7's provisional logo/icon/splash through its
existing fixed-path hooks. Owner decisions: ROGUEWOOD only, no subtitle, one
title-screen action. No bootstrap, UI, project or export changes.

## Before and intent

J01 rendered and JW01 web passed on the provisional UI-7 art. Before captures
are local artifacts/wave13/ui-a4/before/. The title used the bundled font and
the splash/icon reused a cropped House Ball. The final wordmark keeps the warm
brass/wood/petrol palette with custom broad, square-cut arcade letters and open
counters. The icon uses a much simpler ball silhouette, three large ivory holes
and a single gold seam so it remains recognizable at favicon size.

Original OpenAI-generated artwork, no reference images or third-party assets.
Exact prompts: UI-A4-logo-prompt.txt and UI-A4-icon-prompt.txt. Both unchanged
source PNGs are under assets/brand/. Provenance/hashes: ASSET-LEDGER.md.

## Deliverables

- logo.png: original 2172×724 RGBA wordmark, byte-identical to source.logo.png.
  Existing aspect-fit placement supplies the title band; no background plaque.
- icon.png: 512×512 opaque, full-bleed, 32-colour PNG, 111430 bytes (exported favicon 118732 bytes). Original
  source.icon.png is retained. Three holes and a gold seam distinguish the ball
  at 180, 32 and 16 px; the system can apply its own rounded corners.
- splash.png: 720×560 opaque RGB, original wordmark centred on exact #0b1116.
  No subtitle. The web loader and engine use their existing centring/fit rules.
- tools/author_brand.py: deterministic production export/assembly only. It can
  no longer overwrite these with the provisional images. --previews creates
  ignored icon-size review images under artifacts/ui-a4/brand/.

The optional title key art is not needed: the already authored House night hall
and rolling House Ball remain the title composition. No placement hook request.

## Validation contract

Unit, J01 headless/rendered, JW01 web, phone-tour title portrait and landscape,
and actual-size 180/32/16 icon contact. See handoffs/UI-A4.md for final results.
No real iPhone installation, physical audio or desktop browser-tab trial claimed.
