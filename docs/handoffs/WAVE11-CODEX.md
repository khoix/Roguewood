# Wave 11 — Codex close

AV-T01 DONE. Neon rivals and theme are deferred to Wave 12 under the owner's scope fallback. This closes the Codex lane only; Claude integrates and closes Wave 11. No PR to main was opened.

## Landed

- `c1e4310`: merge commit bringing `origin/main` at `710ff7062dd1af018dd015917ed32d19b5b37281` (PR #28) into `codex/roguewood-build`; no rebase.
- `f827768`: AV-T01 implementation, art notes, original synthesized sounds and JAVT01. Enamel charge collar with dim / lit / gold states, stepped glints in two levels, engraved state tab, and Dead Straight's unlit NO SPIN treatment. Screen-position and rendered-radius anchoring support Depth and Flat, including Flat's scaled ball. Glints use the held body's rotation; either reduction option freezes decorative rotation, with no glow loop. Three once-per-hold sounds use PresentationAudio's existing mute, volume, priorities and voice cap. Haptics unchanged.
- `59273da`: move the state tab above the collar after rendered review found it could overlap the existing throw prompt.
- QA registry and art-shard CI edits are add-only. No changes to rules, input, content or physics beyond the requested main merge.

## Validation

Validated 2026-11-10. Pinned Godot 4.5.2 stable, Linux x86-64 Compatibility renderer. Download SHA-512 matches `tools/godot-downloads.sha512`.

- `python3 tools/qa.py unit`: PASS.
- `python3 tools/qa.py content`: PASS.
- `python3 tools/qa.py physics`: PASS. Digest **75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f**, unchanged.
- JAVT01 headless: PASS. Real 540×960 touch holds and swirls through charging, ready and full in Depth and Flat; normal, reduced motion and reduced flash; each signal once per hold; screen anchor/radius checks; existing Dead Straight boss fixture; mute and zero volume.
- JAVT01 rendered: PASS (19 portrait captures); dim, ready, full, reduced and disabled art inspected.
- Existing J02 headless and rendered: PASS; covers calibrated throws, Flat radius/depth, below-start movement, cancellation, mouse, assists and resize.

Evidence (local outputs, deliberately not committed):
- `artifacts/av-t01/validation/av-{unit,content,physics}.log`
- `artifacts/e04/physics-report.json`
- `artifacts/av-t01/{headless,rendered}/journey.log`
- `artifacts/av-t01/rendered/{depth,flat}_{normal,motion,flash}_{charging,ready,full}.png` (18 portraits, 540×960)
- `artifacts/av-t01/rendered/disabled.png`
- J02: `artifacts/e04/{headless,rendered}/`.

## Limits and exact resume

No real-phone or speaker listening trial was performed. The native rendered evidence does not replace the owner's phone feel gate. Physics emitted a non-fatal Jolt job-pool warning; all checks and the baseline digest passed. This environment needed writable XDG directories and execution outside its socket-restricted sandbox; Xvfb was extracted into `/tmp`, with no repository/toolchain edits. Remote CI results are not claimed here.

Claude: merge `origin/codex/roguewood-build` into `claude/roguewood-build`, rerun affected checks/CI, update the central ledger, then close the wave through the established integration path. Keep the owner's current spin-view defaults; AV-T01 does not change them. The merged source defaults to Flat, while the task description called Depth the default; both are explicitly exercised.

Wave 12 Codex (proposed High, bounded rival and theme sessions):
1. Sync main with a merge commit. Read `content/leagues/neon.json` and `docs/handoffs/E17-L02.md` again for any coordinator changes.
2. E21: Slick, Laser Lena, DJ Flicker and DJ Flicker Neon Champion, each with portrait, idle, entrance, six reactions, defeat and reduced-motion versions. Badges: `boss_rule.oil_slick`, `boss_rule.narrow_lane`, `boss_rule.strobe`; champion shows Strobe + Oil Slick seals.
3. E22-L02-ART: Neon theme, Long Oil ending at 47 ft, Two-Tone left dry from 34 ft with a non-colour distinction, Narrow Lane guard lines/rail replacing developmental magenta, and Strobe's narrowed ring zones.
4. Use `--content=neon_c13` and J03C13 to reach all three bosses; add art coverage without deleting QA/CI checks. Leave rules/content/physics to Claude. Record any required hook in the handoff.

No Neon assets are claimed delivered. No captures are tracked.
