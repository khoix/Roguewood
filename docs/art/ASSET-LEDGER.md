# E11 source and asset ledger

| Asset | Source | Rights/provenance | State | Runtime use |
|---|---|---|---|---|
| ART-BIBLE.md | Original Codex-authored project specification | Written for this repository; no external text/assets copied | Proposed | Specification only |
| palette.json | Original project palette/token data | Written for this repository | Proposed | Not wired to gameplay |
| assets/art_direction/candidate-01.png | Built-in image generation from original project brief | AI-generated; no external reference image or branded artwork supplied; do not claim legal clearance or exclusive authorship | Inspected direction candidate; geometry/layout defects in VISUAL-REVIEW.md | Reference only, not a screenshot or sprite sheet |
| Typography | No external font imported | Font redistribution rights not yet selected/verified | Provisional engine fallback | Existing engine UI only |

No production ball/pin/card asset completeness flags are advanced by this ledger. Generated lettering is not production typography. Reference images must be decomposed into authored runtime assets and live UI before engine acceptance. Existing engine/source licenses remain unchanged. No downloaded texture, font, icon pack or third-party brand asset was introduced by E11.

Exact original and edit prompts are in candidate-01-prompt.txt and candidate-01-edit-prompt.txt. Retained PNG is the second built-in generation, unchanged at1024×1536. No external image was used for initial generation; edit input was the first generated candidate. This file is source concept art, not a rendered game capture.

Source transport: the binary upload could not complete through the connector. The unchanged PNG is stored losslessly as numbered base64 parts in assets/art_direction/candidate-01-source/. Run `python3 assets/art_direction/restore_concept.py` to reconstruct it; the script verifies SHA256 before writing. The reconstructed PNG is ignored to avoid duplication.
