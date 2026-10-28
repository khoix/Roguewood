# Codex Wave 4 — final delivery

**Implementation and scoped verification: DONE.** `codex/roguewood-build`.
Wave 3 was already merged to main by PR #14 (`3a7e938`) before work began.
Coordinator `0993250` was merged with commit `43254df`, retaining the Wave 3
integration and CI upload fix. No rebase, force push or PR to main. The containing
commit identifies final delivery; coordinator integrates through
`claude/roguewood-build` and owns the central coordination update.

| Claim | Delivery | Verification |
|---|---|---|
| E17-D03-ART | Nine boss-rule briefs, all 54 exact design IDs; rival-preview card and 48px HUD chip, counterplay, required look-alike flags | `52c5455`; source/ID audit, unit/content |
| E19-A16 | Glass cosmetic scene on real pin body, saved post-bank material transition, artwork flag | `a6fc939`; native shop/placement/inventory/binder, real break/reload/next rack, unchanged body/collision/mass |
| E20-V08 | Seven Charm effects and Glass crack; eight distinct recipes, eight original PCM sounds, effects flags | Containing commit; three-stage native journey, active/quiet cases, ordered breaks, counts, audio starts, 4×/skip/reduced/controls |

## Scope and invariants

Exactly one artwork flag (`pin.glass`), eight effects_audio flags and sixteen
activation/sound paths changed from the coordinator base. The exact eight items
and their resources are listed in E20-V08.md. Glass Cutter's artwork was already
complete on the base; it was preserved. D01/D02/D03 batch files and all authored
flags are byte-identical to the base. Claude's concurrent C03 items remain untouched.

Glass dressing replaces visual meshes only. Its structured saved-break observer
never rolls chance, changes a slot, or writes physics. Crack cues follow the
explanation's confirmed pin order after bank/chance rows; unbroken Glass is quiet
and Echo does not duplicate them. Charm glyph counts and amounts come from the
resolver, not animation state. Existing score/inventory/persistence behavior stays
unchanged, including replay, Skip and reload.

No changes to rules, simulation, persistence, Career, procedural/content code,
throw_lab or clubhouse_model. Shared qa.py, run_tests.gd and workflow edits are
add-only. Parsed YAML comparison preserves the original workflow after removing
the two new steps and two artifact paths; uploads remain inside `with.path` and
`if-no-files-found: warn` remains its sibling. The Codex-owned D02 preview now
allows landed E20 paths while preserving the authored-empty assertion.

## Checks and evidence

Godot 4.5.2 / Linux x86-64. Unit/content PASS with final flags; integration and
smoke PASS. Physics PASS after Glass integration with unchanged digest
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
J03/J05/J06 headless PASS with unchanged results (560/240/70; 21060; existing
Division outcomes). J03C01/C02, J11ART, J19A16, J19A13/A14, J12 and J12V01–V07
PASS in the affected headless/rendered checks. New J12V08 and J12V08C PASS both
modes. No full 110-command CI run is claimed locally; CI runs the complete matrix.

J19A16 checks actual shop purchase and placement, the owned RackSummary, real
binder, real bodies, reduced/landscape views, the C02 seeded break, reload without
reroll and Wood in the next rack. J12V08 checks all eight real activations and
AudioStreamPlayer starts, conditional silence, independent banks and effects
stream, multi-break order at normal and 4× speed, native mute/volume/effects
controls, reduced motion/flash and silent Skip. All voice/world glyph pools stay
at four or fewer. CPU timing diagnostics and their limits are in E20-V08.md;
this is not phone performance or audio-device certification (E26).

Provenance: unchanged original D01 Glass source; eight new original procedural
sounds and glyph recipes. Exact generator parameters and SHA-256 hashes are in
ASSET-LEDGER. Source audio peaks at 0.48; no recordings or third-party samples.

Ignored evidence:

- `artifacts/e19-a16/native/rendered/`: purchase, inventory, binder, diagnostic
  live-rack views, break/reload and `glass_next_rack.png` (Wood 1 / Glass 2–10).
- `artifacts/e20-v08/native/rendered/`: every item activation, ordered Glass
  breaks, 4×, portrait/landscape and reduced captures; per-stage event/CPU/audio
  metrics. `contact/rendered/contact.png` shows all eight normal/static recipes.
- `artifacts/wave4/validation/`: A16 results, legacy headless and rendered final
  manifests, final suites, exact scope audit and PCM/hash audit.

Captures were inspected; screenshots are not committed. CI regenerates/uploads
the new journeys through the existing workflow.

## Hand-off

All three Codex Wave 4 claims are DONE within scope. Coordinator can merge the
Codex branch, reconcile with concurrent C03, and close the wave after integration
checks. There is no pending-owner status or separate approval queue.

Stop here: D03 identity art belongs to Wave 5 (recommended Medium once claimed).
D04 briefs follow its authored handoff and next-wave claim. No D03 illustrations,
new E21 rivals, E22 or other next-wave work was started. Physical-phone checks
remain E26.
