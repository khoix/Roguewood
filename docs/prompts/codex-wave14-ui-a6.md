UI-A6 (Wave 14, added by the owner's play notes of 2026-11-15; continue in your Wave 14 session): a themed pin deck for every League.
Recommended effort: Medium (High if the House finish needs new art beyond a shader).

The owner's note: "Some pin areas still don't have any thematic decoration." Their capture is a House League feature match on a phone. Behind the pins, the kickbacks and the cushion are the lane's plain wall colour.
- **Why:** `LeagueTheme._dress_pin_deck` (src/presentation/league_theme.gd, your Wave 13 tail) dresses those meshes only when the manifest is the Neon League's. The House League has no pin-deck finish at all.

First, merge `origin/claude/roguewood-build` (the UI-9 commit or later) into `codex/roguewood-build` with a merge commit.

Do:
1. **The House League's pin deck:** a finish for the visible kickback and cushion meshes that suits the House hall (warm wood, brass, the club at night), as a material or shader in assets/leagues/house/.
   - Static, like Neon's: no TIME, lighting, geometry or collision changes.
   - Read at phone size from the behind-ball and roll views.
   - Check every House stage: Divisions 1 to 8 and the Championship.
2. **Make the hook data-driven:** each League's manifest names its pin-deck asset (for example `pin_deck` in `assets`, or a `pin_deck` entry), and `_dress_pin_deck` applies whatever the manifest names.
   - A League without one keeps the plain walls.
   - Move Neon's finish to the same entry.
   - Salvage's own finish comes with its theme in Wave 15.
3. **The rest of the pin area:** look at what else shows there in the roll view. If the pit's edge or the area above the cushion still reads as plain, dress it the same way, on presentation meshes only.

Keep:
- **Leave the physics alone:** the lane world's bodies, shapes and physics materials, and the physics digest `75d1a3c0…`.
- **Leave the scoring and the lane surfaces alone:** J03 560/240/70 and J05 21060; the per-condition lane surface materials.
- **Reduced motion:** your finish is static, so nothing changes.

Paths:
- src/presentation/league_theme.gd (the pin-deck hook only);
- assets/leagues/house/ and assets/leagues/neon/ (the manifests' pin-deck entries and the finishes);
- your art journeys or capture tools;
- docs/art/ (a brief docs/art/ui/UI-A6.md);
- docs/art/ASSET-LEDGER.md.

Nothing else in src/, content/ or the tests. tools/qa.py, the CI workflow and run_tests.gd are add-only, and every new art step has `if: matrix.shard == 'art'`.

Check natively:
- A House League journey or capture shows the finished pin deck, headless and `--rendered`, in portrait and landscape: a feature match in Division 2, a boss match and the Championship.
- Neon's pin deck is unchanged (J22L02LIVEART).
- J22L01, J22L02, J06, J11 and J11ART still pass.

When done:
- Add UI-A6 to WAVE14-CODEX.md.
- Write docs/handoffs/UI-A6.md: what you changed and why; the captures the owner should review, which are the House pin deck in portrait and landscape at Division 2, a boss and the Championship, and Neon's for comparison.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
