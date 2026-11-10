# UI-A3 — numeral legibility

Status: DONE. Implementation, visual review and scoped validation complete.

## Scope and source

Patched `assets/ui/fonts/PixelifySans.ttf`, replacing only `two` and `five` with
original curved outlines. Existing preloads receive the patch automatically;
Claude does not need to wire a second face. Advances and character mappings are
identical. The internal family is Roguewood Numerals. The original OFL licence
remains intact; source, modification and reserved-name rule are recorded in
ASSET-LEDGER.md and docs/art/ui/UI-A3.md. The reproducible contour script lives
beside that brief. Other font glyphs, gameplay and UI source are unchanged.

Before-work plan: patch the bundled face; cover score slip, frame review/rack,
shop prices/money and tuning through the existing 780×1688 phone tour; run unit,
content and J03/J05/JUIA1/JUIA2 in both modes. Also run the requested core
regressions and physics. No journey or CI checks are removed or edited.

## Evidence

Godot 4.5.2 standard, checksum verified against tools/godot-downloads.sha512.
Engine: `/tmp/roguewood-godot/Godot_v4.5.2-stable_linux.x86_64`.
Xvfb extracted to `/tmp/roguewood-xvfb`; display `:99`.
Writable XDG_CONFIG_HOME, XDG_CACHE_HOME and XDG_DATA_HOME are respectively
`/tmp/roguewood-config`, `/tmp/roguewood-cache`, `/tmp/roguewood-data`.

- J03, J05, JUIA1 and JUIA2: PASS headless and rendered. J03 remains
  560/240/70; J05 remains 21060.
- Physics: PASS, digest `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
- Unit and content: PASS (`/tmp/uia3-unit.log`, `/tmp/uia3-content.log`).
- Font-table audit: PASS; only two/five contours differ; hmtx and cmap identical.
- Type comparisons: `artifacts/ui-a3/uia3-type.png` (2×), `artifacts/ui-a3/uia3-type-3x.png` (3×),
  at 16, 20, 24, 30 and 36 logical px. Source left, patch right.
- Native before/after tours: `artifacts/ui-a3/before/`, `artifacts/ui-a3/after/`.
  Review `14_tuning.png`, `15_aim_assist.png`, `17_scoring.png`,
  `18_frame_done.png`, `19_shop.png` and `22_shop_after_buy.png`.
  Frame done includes both the small score slip and the numbered rack.
- Journey logs: `/tmp/uia3-<journey>-{headless,rendered}.log`.
  J02, JAVT01, J06, J22L01, J03C13, J11 and J11ART all PASS headless
  and rendered. No regression failure was observed.
  The entire historical art shard was not rerun in this bounded font session;
  no QA registry, CI workflow or existing checks were changed.
- Both tours completed all 26 captures. Inspected patched tuning, frame review
  and shop: the 2/5 are distinct at actual UI sizes without visible reflow.

Validation logs are copied to `artifacts/ui-a3/validation/`.
No screenshots or rendered captures are tracked. No physical-phone trial.

## Coordinator and resume

Merge this Codex checkpoint through the established coordinator branch. No font
wiring is needed. Continue with E21-R05 (High), including the three missing House
plaques; exact resume steps and owner captures are indexed in WAVE12-CODEX.md.
