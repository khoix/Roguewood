# Codex brief — AV-FIX1, transparent card art (owner, 2026-11-17)

Owner: "A number of images aren't transparent — they have background colors that need to be removed." The owner's screenshots show the Binder, where these cards show a dark rectangle inside the card's art window.

## The eight cards
The coordinator scanned every catalogue card. These are the only ones whose border is fully opaque (alpha > 0.9 on 100% of edge pixels), all on a dark background of about #0E1920:

| Item | Card resource | Source sheet |
|---|---|---|
| pin.tin | assets/items/d09/card.pin.tin.tres | source.AV-H3-B.png |
| charm.spare_jar | assets/items/d09/card.charm.spare_jar.tres | source.AV-H3-B.png |
| charm.consolation_prize | assets/items/d09/card.charm.consolation_prize.tres | source.AV-H3-B.png |
| consumable.double_take | assets/items/d10/card.consumable.double_take.tres | source.AV-H4-A/B.png |
| consumable.called_shot | assets/items/d10/card.consumable.called_shot.tres | source.AV-H4-A/B.png |
| consumable.pin_count | assets/items/d10/card.consumable.pin_count.tres | source.AV-H4-A/B.png |
| charm.cleanup_crew | assets/items/d10/card.charm.cleanup_crew.tres | source.AV-H4-A/B.png |
| charm.lucky_seven | assets/items/d10/card.charm.lucky_seven.tres | source.AV-H4-A/B.png |

The other 89 cards are transparent at the edge, so they are not affected. The icon, reduced-motion and in-play views that reuse these regions need the same fix.

## What to do
- **Give each subject a clean alpha matte:** no dark plate, halo or fringe, and soft edges kept, as the other cards have. Contact shadows that belong to the subject may stay, such as the coins by the jar or the pins under the brooms.
- **Pick the method; record it either way.** Either regenerate transparent sources, or derive matted images from the existing sources. Record the new or derived files, the method and SHA-256 in docs/art/ASSET-LEDGER.md. The original sources may stay as provenance.
- **Add a guard** so this cannot return. A unit check that every catalogue item's card (and icon) is transparent at its border, for example less than 5% of edge pixels opaque. It currently fails for exactly these eight. This is Codex's own art test; it is in scope.

## Evidence
- **Captures:** Binder and shop captures of the eight cards, before and after, in both orientations.
- **Checks:** the existing art journeys for these batches (JAVH3B and the AV-H4 journeys), `unit` with the new guard, and J11.
