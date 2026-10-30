# AV-C04-A — Brass Cap, Gilt Leaf, Keystone

Implementation and scoped verification: **DONE**. Codex / codex/roguewood-build. Wave 6 coordinator
base `046b04d`, merged with `257b497`. The containing delivery commit identifies
this batch; branch/remote are verified separately after push.

## Before

Three items: pin_mod.brass_cap, pin_mod.gilt_leaf, pin_mod.keystone. Exact six
IDs per item from E17-D04 landed design blocks: icon, card, rarity_treatment,
activation, sound, reduced_motion. No invented in_play asset slots.

Original generated pixel-art object illustrations, saved unchanged with prompt
and hash; AtlasTexture resource views only. Small cosmetic 3D cap, partial torn
leaf patch and trapezoid plate follow real host bodies. Host material, silhouette,
physics and identity remain. Icons also act as host badges. Original vector
activation motifs and synthesized PCM foley, exact resolver event ownership.

Native JAVC04A: real shop offers, purchase/host choice, inventory/binder, bare vs
modified body checks, physical strike and quiet cases, counted Keystone, Gilt
Leaf after-bank only, no invented host activation, audio starts, reduced/Skip/4x,
portrait/landscape and reload. Contact proof: 32/64/192px, grayscale/silhouette,
normal/reduced effects. Unit/content and affected native regressions, unchanged
physics digest and J03/J05/J06. Flags only after native verification.

Then AV-C04-B (Chalk Grip, Spin Wax, Coin Slot), AV-C04-C (Echo Charge, Lantern),
then E22-L01-ART. No future content flags, rules/physics/persistence or League edits.

## Implementation

Eighteen exact declared resources are bound to the three catalogue items. The
original generated PNG and prompt are retained; AtlasTexture views avoid faint
alpha specks in the source margins without editing the image. ASSET-LEDGER records
source/audio hashes and original geometry/vector/PCM provenance. Smooth dome,
torn diagonal leaf and notched trapezoid read distinctly at 32/64/192px, including
grayscale and silhouette. The leaf is a partial patch, distinct from Gold Pin's
whole-body identity. Brass Cap leaves Crown points clear with a small side plate.

`modification_art.gd` observes real attachments, gives the shop's rack summary
host icons plus badges, and dresses the actual pin body with a small cosmetic
mesh. Reusable hand/inspector/card-host badge bindings are ready for the next
ball-modification batch; their four identities/overlays are not delivered here.
No collider, mass, material replacement, gameplay state or saved data is owned
by this observer. Invalid/freed preview balls are ignored before typed access.

Before banking, the adapter retains a bounded attachment snapshot keyed by frame
number. `modification_events.gd` combines catalogue effects in their exact joined
order and checks equality against the scored frame before mapping effect_index.
A modification's row cannot impersonate its host. Echo's separate retrigger cause
survives that filtering, including a Crown host whose only paid row is its mod.
No text/name matching or animation-derived amounts. Counts and amounts remain
resolver-owned; Keystone outlines the actual fallen slots in the rack diagram.

Brass Cap: one +1 Mult rim tick for each actual fall/repeat. Gilt Leaf: one
$1 coin accent at after-bank only, soft foil plus one delayed coin tick. Keystone:
counted trapezoid, actual down-slot outlines, exact +4-per-down amount and dry
stone/wood tap. Reduced motion and flash keep a static construction and native
text. The existing sound/voice and visual pools remain bounded.

## Native verification

JAVC04A uses actual Pro Shop offers, rerolls, payments and host choices at rack
1/3/5, then inventory, binder, menu reload and physical throws. Explicit fixtures
only fund the wallet and enable Division 2/unlock offer eligibility. They do not
fabricate reports, events, banks, income or card attachments. Keystone may still
read Locked in the Career binder under this shop-eligibility fixture; that native
state is deliberately preserved while its actual owned attachment is verified.

- Echo strike: 190 Value x(6 + actual release-grade bonus), two Brass Cap cues,
  one Keystone count of 10/+40, one after-bank Gilt Leaf coin. Headless banks
  1,140; the extra rendered close-up frames can earn Sweet (+1, bank 1,330).
  The test checks the actual grade and independent resolution, not wall timing.
- House strike: 900 = 180 Value x5 Mult, one cue each, one coin.
- Two gutters: 0, no modification activation.
- Each cue is checked at its own explanation row; Keystone's outlined slots
  equal its resolver count. Body identity, mass and collision stay unchanged.
- 4x replay preserves cue order/details; mute, zero volume, effects toggle,
  reduced motion/flash and silent Skip preserve bank/inventory. Menu reload
  retains attachments. Portrait/landscape controls and badge bounds are checked.
- Unit cases cover Wood/Crown/Glass/Grower, direct-pin repeats, deferred Gilt Leaf
  deduplication, partial Keystone count [1,5,10], exact ownership, mismatched
  snapshot refusal and input immutability. Injected failure exits 1 as expected.

Unit/content PASS with final flags. JAVC04A and JAVC04AC PASS headless/rendered;
final host close-ups, shop/binder, small-size/contact, activation and reduced
captures inspected. The textured leaf and stone patches retain their source
material detail in lane lighting. The native close-ups inspect actual equipped
bodies in isolation; all other pin visibility and camera settings are restored
before physical throws.

All 28 regression commands PASS: JAVC04A/AC, J03C01/C02/C03/C04, J11ART,
J12V08, J19A16, JAVC03A/B, J03, J05 and J06, each headless and rendered.
Final A headless/rendered re-runs follow the texture/inspection correction.
J03 remains 560/240/70, J05 remains 21060 and J06 retains its prior outcomes.
Physics PASS with the digest below. Injection exits 1 with only its expected
injected assertion. The final source/PCM/scope audit is recorded under validation.
A is DONE; the other Wave 6 batches remain implementation work, not user review.

## Scope and evidence

Catalogue diff against `046b04d`: only these three items, six paths each and
artwork/effects_audio flags. No authored batch or League spec changes. Rules,
simulation, persistence, Career, procedural/content code, throw_lab,
clubhouse_model and central AI-HANDOFF are unchanged. Shared qa.py/run_tests and
workflow changes are add-only. Parsed workflow comparison preserves existing
steps, upload structure and the coordinator's 90-minute timeout.

Ignored evidence (no captures committed):

- `artifacts/av-c04-a/native/rendered/`: shop, owned badges, inventory, binder,
  actual host overlays, three individual native 3D viewport close-ups (other pins hidden only for
  isolated inspection, restored before the throw),
  activations, Echo repeat, reduced/landscape, metrics.json.
- `artifacts/av-c04-a/contact/rendered/contact.png`: 32/64/192px identities,
  grayscale/silhouette, animated sample and reduced construction.
- `artifacts/wave6/validation/`: per-command logs, progress/final manifests,
  scope-a.json and audio-a.json. Physics digest remains
  `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.

Environment: Godot 4.5.2, Xvfb/llvmpipe, two-CPU quota. Dummy audio proves actual
player starts/PCM/control behavior; it does not certify physical-device mix or
latency. No GPU/phone performance or full CI-matrix pass is claimed. Platform
checks remain E26. These are implementation limits, not an owner approval queue.

## Exact resume

Continue Wave 6 with AV-C04-B (Medium): Chalk Grip, Spin Wax, Coin Slot, their
six exact IDs each from the D04 landed blocks. Extend tools/author_c04_art.py,
assets/items/d04/overlay.gd and the presentation bridge; verify actual modified
Hook/Hook/Hammer cards in shop, hand/inspector, binder and throws before flags.
Then AV-C04-C (High): Echo Charge and Lantern. E22-L01-ART (High) follows: House
Division progression 1–8, Championship, House Oil/Dry Backend visuals and music,
verified in preview/contact/inspector only, with ID/drop-path contract for Claude's
Wave 8 integration. None of those remaining assets/flags are delivered by A.
