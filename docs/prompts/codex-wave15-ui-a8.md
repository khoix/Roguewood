# Codex brief — UI-A8, League backdrops (Wave 15)

Owner request, 2026-11-17:
> "Redesign the backdrop for existing leagues. It needs to fit the theme of the league. For example, the Spectral league might have spooky things floating around in a darker background. For Neon, that might be more neon, glowing colors or strobe light (not a stated requirement, just an example). The background needs to be ambient but pushing the theme forward visually. The current backgrounds are very plain and don't pull the theme together."

## Scope
- **The backdrop is the space beside and behind the lane:**
  - the flank backdrop (`LeagueTheme.flank()`, House's night sky `assets/ui/backdrops/house.gd`, Neon's manifest `flank` entry);
  - the far view behind the pins in each Division room, where the room shows the sky or the hall beyond.
- **Leagues now:** House and Neon, for every Division and the Championship.
- **Leagues later:** Salvage, Royal, Spectral and Foundry get theirs as part of their League themes (E22-L03-ART onward), to the same standard. Write that standard into this task's handoff so each later theme follows it.
- **Lane, pins and UI:** the lane, pins and pin deck (UI-A6) stay as they are, as do the interface frames.

## What it must do
- **Push the theme forward.** It should be unmistakably this League at a glance, with the identity carried by shapes, motion and colour, not by a flat tint. For example:
  - **House:** a warm, old-fashioned hall at night.
  - **Neon:** glowing signage, light spill and colour sweeps; any strobe stays slow and soft.
  - **Spectral:** drifting shapes in a dark field.
  These are examples, not requirements; Codex owns the art direction.
- **Stay ambient.** Slow, low-contrast motion that never competes with the ball, the pins, the score review or the HUD. Nothing should pull the eye during a throw. Keep the HUD and text readable over it.
- **Have depth.** Layers (far, middle, near) with gentle parallax or drift, not one flat image.
- **Vary by Division.** Keep each Division's room character (as the Neon rooms do) and build to the Championship.
- **Both orientations.** Portrait (narrow flanks at 540 wide) and landscape (wide flanks, folding on 4:3), at phone and desktop sizes.
- **Reduced motion and reduced flash:** a still or near-still version. No flashing faster than 3 a second in any mode, and no strobe at all under reduced flash. This matters for players who are sensitive to light.
- **Performance:** the Web build on phones (Compatibility renderer, single-threaded). Particle counts and shader cost stay within budget; record the frame time against the current backdrop in the handoff.

## Integration
- **Keep the existing hook:** the theme's manifest names the backdrop, and the node has a `reduced` property.
- **New hooks:** if the design needs one (for example a per-Division backdrop, a pulse with the music, or a match-state reaction), request it in the handoff. Claude owns `league_theme.gd` and the lab; propose the interface and Claude wires it.
- **Assets:** original only, with sources, prompts and hashes in docs/art/ASSET-LEDGER.md, as before.

## Evidence
- **Captures:** native captures for each League, Division room and orientation, and reduced motion, via the theme journeys (J22L01ART and J22L02ART, or a new UI-A8 journey).
- **Checks:** `unit`, J22L01, J22L02 and their art journeys, J11 and `web`. The physics digest stays `75d1a3c0…` (backdrops are cosmetic).
- **Handoff:** the frame-time comparison, and the standard for the later Leagues.
