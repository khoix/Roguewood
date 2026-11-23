# Boss rule ideas for later (owner, 2026-11-18)

Not scheduled. The six planned Leagues already have all 20 of their rival rules
(content/leagues/rivals.json). These are proposals, kept for a seventh League or
later, for endless and difficulty modifiers (E23), or to replace a weaker rule.
The owner liked all of them. Names are provisional; each needs a spec before it
is built.

## The owner's ideas
- **Wrong Hand** (hooks only, one way): every throw must hook against the player's
  own hand. Set by handedness, not literal left or right, so left-handed players
  face the same test. A throw that does not hook that way scores no Value; the HUD
  marks it at release. The opposite of Dead Straight.
- **Courtesy Pin** (knock down all but one): a frame counts only if exactly one
  pin stands at its end; a strike is a miss. Makes pin placement and the rack map
  matter in a new way. As a champion's pair with Court Order: head pin first, then
  leave one.
- **Speed Limit:** a ball over the limit scores no Value ("School Zone"), or a
  narrow band to stay inside ("Cruise Control"). Needs a speed readout first,
  ideally on the charge. Combines well with Heavy Set.

## Claude's additions
- **Called Shot:** before each roll the rival names a pin (seeded, so it repeats);
  if it stays up, the frame's Value is halved.
- **Locked Line:** the first throw's target is fixed for the whole match.
- **Crosswind:** a steady sideways drift on the ball, shown by an arrow; a lane
  condition rather than a scoring penalty.
- **Shrinking Ring:** the target ring's sweet spot shrinks each frame; a harder,
  building Strobe.
- **Blind Rack:** after the first roll the standing pins are hidden until the
  throw; aim the spare from memory (a Spectral fit).
- **Odd Pins Only:** only odd-numbered pins score Value.
- **Toll Lane:** each roll costs $1, reaching into the next shop.

## Limits for every rule
- Works with Assist Controls (the spin slider counts as a hook) and Reduced Motion.
- No timer that punishes a slow player (no shot clock).
- Fits the lane conditions it is paired with; deterministic under the seed.
- One rival per rule, as now.
