# Roguewood
**Game design and build plan.**

Approved game title: **Roguewood**. No subtitle. Use this title consistently on the title screen, logo, menus, and promotional artwork. Name availability has not been checked. Research reviewed October 25, 2026.

Revision 5 — October 25, 2026: incorporated approved named-rival bosses, objective-based encounters, themed lane presentation, reactions, and defeat sequences.

Revision 4 — October 25, 2026: made premium pixel-art execution, dynamic effects, early visual validation, and release-blocking quality gates explicit.

Revision 3 — October 25, 2026: added persistent Career progression, thematic Leagues, unlock rules, and separation of Leagues from Divisions.

Revision 2 — October 25, 2026: expanded full-release content targets, procedural generation, item economy, individual visual specifications, and holographic collectible cards. The draw/cycle rules below are a proposed implementation to test, not a user-approved final mechanic.

## 1. Product direction

A mobile-first, single-player bowling roguelike: spin and flick a ball down a surreal pixel-art lane, knock over a rack you have customized, then watch ball effects, pin effects, and collectible modifiers turn a small bowling result into an enormous score.

The central promise: **build a scoring engine that changes how you want to bowl.** Sometimes a strike is optimal. Sometimes deliberately leaving one valuable pin standing is better.

Visual target: a close Balatro-like aesthetic—chunky pixel art, tactile collectible panels, animated color fields, optional CRT treatment, and exuberant score resolution—translated into a bowling-alley composition with original artwork, typography, sounds, and branding. This plan interprets “visually identical” as strong stylistic fidelity, not an exact screen or asset reproduction.

Assumptions: touch-first, mouse-compatible, playable offline, no multiplayer in the initial release, no real-money gambling, and no requirement for realistic regulation scoring. All numbers below are proposed prototype values, not validated balance.

## 2. What the research establishes

| Observed reference | Evidence | Design implication |
|---|---|---|
| Balatro asks players to exceed score requirements across Small, Big, and Boss Blinds; its traditional finish is Ante 8. | Official FAQ [1] | Make escalating score checks and disruptive bosses the run structure. |
| Jokers can change scoring, card behavior, and economy; Tarot modifies the underlying cards. | Official FAQ [1] | Separate passive build modifiers from permanent customization of the pins themselves. |
| Chips and Mult combine to form hand scores, with ordered effect resolution. | Community scoring documentation [4] | Give the player a visible two-part score and explain every modifier in order. |
| Balatro combines pixel art, CRT effects, a psychedelic presentation, and music with a broad set of upgrade systems. | Publisher page [2] | Presentation must amplify the build, especially during scoring. |
| LocalThunk describes familiarity as an onboarding tool and risk mitigation as a central strategy. | Direct interview, March 7, 2024 [3] | Familiar bowling should teach the game; unfamiliar combinations should sustain it. |
| Pokémon GO uses hold-and-fling input, a shrinking target ring, and circular pre-throw motion for curveballs. | Official help [5] | Borrow the continuous gesture vocabulary and readable accuracy feedback. |

Research limitations: this is a source-based design analysis, not a hands-on timing study or reverse engineering of either game. Official pages are undated and can lag releases; the interview is dated historical evidence. A recent-change search was also performed, but unreleased Balatro changes are not dependencies of this design. Exact throw constants and visual timings require prototype testing.

## 3. Translate the systems, not just their names

| Balatro role | Bowling equivalent | Player decision |
|---|---|---|
| Playing cards/deck | Persistent collection of individual pins | Which pin effects belong in this run? |
| Played hand | Completed frame: strike, spare, or open | Which result suits the build? |
| Joker row | Five collectible “Charms” | Which synergies and ordering maximize score? |
| Hand upgrades | Technique lessons | Improve strikes, spares, or open frames for the run. |
| Card transformation | Pin workshop | Change a pin material, value, or scoring property. |
| High-risk transformations | Experimental equipment | Trade reliability, capacity, or money for unusual effects. |
| Vouchers | Pro-shop licenses | Upgrade shop, bag, or consumable capacity for the run. |
| Starting deck | Starting bowling kit | Choose a different starting constraint and advantage. |
| Blinds/Antes | Matches/Divisions | Meet larger targets while preparing for the boss. |
| Discard-like flexibility | Limited pin swaps and consumables | Spend resources to improve the current situation. |

Do not force an equivalent for every Balatro rule. Pins have spatial relationships and physical behavior; that should supply original strategy.

## 4. The run and frame rules

**One League attempt:** eight Divisions, each containing an opener, a feature match, and a boss. That is 24 matches. Target duration: 30–45 minutes, to be measured.

**One match:** accumulate the target score within two frames. Each frame starts with ten active pins and permits up to two rolls. A first-roll clear is a strike; a second-roll clear is a spare. Otherwise it is an open frame. A strike ends the frame immediately. There are no tenth-frame bonus rolls or regulation carry-forward bonuses.

Score the entire frame once when it ends. During rolls, show provisional pin values and physical effects; do not award the same pin twice across the two rolls. Crossing the match target ends the match after the current frame resolves.

**Between matches:** collect payout, visit the shop, modify the rack, reorder Charms, and select equipment. Preview the current Division’s boss before purchasing.

**Run loss:** fail a target after both frames. **Run win:** beat Division 8’s boss, with optional endless continuation.

**Starting kit:** one unlimited-use House Ball, ten Wood pins, two empty reserve-pin slots, five empty Charm slots, two consumable slots, and $6. The proposed equipment-deck rules in Section 15 replace the original three-ball bag constraint.

**Rack editing:** ten fixed triangular positions; swap individual pins between positions freely between matches. Reserves hold up to two additional pins. Lock the lineup for the match unless a specific consumable permits a swap. Upright survivors stay where physics leaves them for roll two. Fresh frames restore the selected lineup and positions. Falling does not permanently destroy a pin unless its text explicitly says so.

**Equipment access:** use the proposed draw-and-cycle system in Section 15. The House Ball remains available outside the deck. Special ball cards cycle after use; per-card charges apply only where explicitly specified. This replaces the original House Ball plus two specials / two uses per match rule.

Defer skip rewards until normal pacing and economy are proven. They are optional later complexity.

## 5. Throwing: Pokémon GO gesture, bowling outcome

The ball sits large at the bottom of the screen. The lane recedes toward the rack. Hold the ball, optionally circle it to charge spin, and flick forward to release.

| Gesture | Result | Feedback |
|---|---|---|
| Hold and drag sideways | Set starting position within the approach | Ball follows the finger; foul-line marker shows alignment. |
| Circle while holding | Charge signed spin, capped at a readable limit | Animated arrows and a small spin meter. |
| Flick upward | Launch; final direction sets angle, speed sets power | Brief direction trail and power indicator. |
| Release after a valid flick | Commit the shot | Haptic/audio cue and immediate motion. |
| Release without a forward flick | Cancel safely | Return ball without consuming a roll or use. |

**Separate phases inside one gesture:** circular samples charge spin; only the final forward segment determines release direction and power. Otherwise the final tangent of a circle could launch the ball sideways unintentionally.

Use viewport-normalized input and timestamps. Estimate release velocity over a short recent sample window, initially 80–120 ms; tune with actual devices. Cap speed rather than rewarding arbitrarily violent swipes. Show a short directional guide, not a perfect forecast of every collision.

**Target ring:** a contracting ellipse sits at a chosen impact point near the pin deck, initially the conventional strike pocket. The player can move the target before holding the ball. Freeze ring size at release; award a modest accuracy bonus only if the ball center crosses the target plane within the frozen ring. A narrow ring yields the largest bonus. This is our adaptation, not a claim about Pokémon GO’s internal implementation.

Suggested grades: Clean +0 Mult, Sweet +1 Mult, Perfect +2 Mult. Missing the ring gives no bonus but does not force a gutter. Target timing must not overpower equipment strategy.

**Roll, do not lob:** the ball may make a tiny release hop, then travel down the lane. Spin becomes a hook influenced by surface and ball grip. Stronger speed should trade off against hook control rather than simply being better.

**Accessibility:** adjustable sensitivity, left/right-handed placement, reduced motion, larger touch targets, and an alternate aim–power–spin control scheme that emits the same launch parameters. No mandatory timing pressure while browsing items.

**Feel tests:** first-time players should intentionally release a straight ball within three tries and distinguish clockwise/counterclockwise spin within ten. Ask players to explain misses. If they blame unexplained randomness, fix input or feedback before adding content.

## 6. Scoring and resolution

The two large score counters are **Pin Value × Mult**. Regular bowling contributes recognizable outcomes, not a 300-point ceiling.

| Frame category | Base Pin Value | Base Mult |
|---|---:|---:|
| Open | 0 | 1 |
| Spare | 20 | 2 |
| Strike | 40 | 4 |

Each Wood pin knocked down contributes 10 Pin Value. A base strike therefore scores (40 + 100) × 4 = **560**. A base spare scores (20 + 100) × 2 = **240**. Nine Wood pins in an open frame score 90.

Frame category is exclusive. Tags such as curved shot, split conversion, or consecutive strike can additionally activate equipment. Straight or curved depends on committed spin exceeding a documented threshold, not visual guesswork. Accuracy bonus uses the best valid grade across the frame, once.

**Fixed order:**

1. Set frame-category base values.
2. Resolve fallen pins by original rack position 1–10, including explicit retriggers.
3. Resolve standing-pin effects by rack position.
4. Apply frame-level ball effects in roll order, then the single accuracy bonus.
5. Resolve Charms left to right, applying each addition or multiplication immediately.
6. Multiply final Pin Value by final Mult, round down once, and bank it.
7. Apply payouts, growth, and breakage for future frames.

Physical effects happen during the roll; score effects happen after classification. A retrigger repeats a pin’s permitted scoring effect, not its explosion or an entire collision chain. All effects declare their scope: roll, frame, match, or run.

**Worked build:** strike with eight Wood pins and two Ruby pins; Ruby contributes 10 Value and +2 Mult each. Base becomes 140 Value and 8 Mult. A Flat Bonus Charm gives +4 Mult, then a Finisher gives ×2 Mult: 140 × (8 + 4) × 2 = **3,360**. Reverse the Charms and it becomes 140 × (8 × 2 + 4) = **2,800**. The interface previews this ordering consequence.

Round targets start at a proposed 160 / 260 / 400 for Division 1. Later targets come from measured build performance, not blindly extrapolating those numbers.

## 7. Ball catalogue

The following eight are initial designs within a full-release target of 24 distinct base ball types. Prototype the first four, then develop the remaining catalogue through the content gates in Section 15. In the table, references to two uses per match are superseded by card cycling; individual charge limits must be defined during balance work.

| Ball | Effect | Cost or tradeoff |
|---|---|---|
| House | Predictable medium mass and grip | Unlimited; no scoring bonus. |
| Hook | Higher response to charged spin | Easier to overcurve; two uses/match. |
| Hammer | Higher collision impulse | Reduced hook; two uses/match. |
| Echo | Retriggers the scoring effect of the first pin it directly knocks down | Once per roll; two uses/match. |
| Spark | First direct impact pushes nearby pins within a visible radius | Harder to preserve standing-pin setups. |
| Ghost | Passes through the first contacted standing pin, then becomes solid | Sacrifices an easy front hit to target the back row. |
| Splitter | Splits into two weaker balls after a marked lane line | Less predictable coverage; both count as one roll. |
| Gold | +$1 for every three unique pins it knocks down during its roll | Lower impulse; income cap $3/roll. |

Every special must change aim, scoring, or resource decisions. Recolors alone are not separate ball types. Attribute knockdowns to the originating roll and ball, including downstream pin collisions, with one credit per pin.

## 8. Pin catalogue

Pins are player-owned ingredients, not only enemies. These ten initial designs are a subset of the full-release target of 32 distinct pin types. Materials alter economics and scoring; a smaller subset changes physics.

| Pin | Proposed rule | Strategic role |
|---|---|---|
| Wood | +10 Value when down | Baseline. |
| Ruby | +10 Value and +2 Mult when down | Reliable multiplier build. |
| Gold | +10 Value and $1 when down; once/frame | Economy. |
| Glass | +30 Value; 20% chance after scoring to revert to Wood | High output with maintenance risk; no missing rack slots. |
| Anchor | +10 Value when down; +3 Mult if standing at frame end | Intentional non-clear build; greater mass. |
| Echo | +10 Value; repeat the preceding fallen pin’s basic Value/Mult effect | Rack-order puzzle; no copying retriggers, income, or breakage. |
| Fuse | +10 Value; on first fall applies one local physical impulse | Chain-reaction clearing; once per frame. |
| Grower | Starts at +10 Value; gains +5 for future frames when knocked down | Long-term investment. |
| Crown | +40 Value only if it is the last unique pin knocked down | Precision targeting; zero Value otherwise. |
| Rubber | +10 Value; higher restitution | Alternative pin scatter and bank shots. |

Identify materials with shape markings as well as color. Show exact effects on tap and make crowded rack inspection available as a flat ten-slot diagram.

## 9. Charms and viable builds

Five Charm slots impose opportunity cost. These ten examples begin a full-release target of 100 Charms. Each is represented by a collectible card depicting bowling objects—score slips, trophies, shoes, vending tokens, and patches—with rarity-specific framing.

| Charm | Prototype effect |
|---|---|
| Flat Bonus | +4 Mult every frame. |
| Finisher | ×2 Mult on strikes. |
| Spare Change | +6 Mult on spares. |
| Lone Survivor | ×3 Mult on open frames ending with exactly one standing pin. |
| Hook Artist | +4 Mult if either roll had qualifying charged spin. |
| House Favorite | +60 Value if every roll used the House Ball. |
| Gold Rush | +2 Mult per Gold pin knocked down this frame. |
| Turkey Club | ×2 Mult from the third consecutive strike onward; non-strike resets streak. |
| Patient Investor | +1 permanent Mult after each completed match; starts +0. |
| Last Chance | ×2 Mult on the second frame of a match. |

Desired build families: strike chains, spare conversions, standing Anchor/Lone Survivor, Gold economy, Echo retriggers, and Grower investment.

**Balance test:** upgraded non-strike builds must beat plain strikes in their intended conditions. Do not add pity bonuses to every mistake; create deliberate alternative objectives. No single special ball should be mandatory across these families.

## 10. Shop, progression, and bosses

**Proposed economy:** $3 match payout, +$1 per unused frame, and $1 interest per $5 held, capped at $3. Common pin $3, common special-ball card $5, common Charm $4–6, technique lesson $3. Full-release rarity bands and economy rules are specified in Section 15. Rerolls begin at $2 and increase by $1 within the shop. Sell items for half purchase price, rounded down; the House Ball cannot be sold. Values require simulation.

Shop offers: two Charms, one ball/pin equipment card, one tactical consumable, one lesson/workshop option, and a reroll. Section 15 governs selection weights and exclusions. Purchases for full slots require an explicit replacement or cancel. No silent deletion.

Technique lessons level one frame category for the run: prototype +10 base Value and +1 base Mult per level. Workshop changes a chosen pin; it does not randomly overwrite the rack. One-use consumables can relocate a standing pin, swap one reserve pin into the next frame, or cancel a boss penalty for one roll.

Between-run unlocks add alternative kits and content, not stacking permanent score boosts. Later add challenge modifiers, seeded runs, and a collection journal.

| Boss | Rule | Counterplay |
|---|---|---|
| Oil Slick | Hook strength reduced 50% | Straight-line targeting or stronger-spin equipment. |
| Heavy Set | Pin masses increased 50% | Hammer Ball or spare-focused scoring. |
| Clean Sweep | Only strike/spare frames bank points | Prepare clearing equipment; rule announced before the Division. |
| Frugal House | No income from pin or ball effects | Survive on scoring strength and saved money. |
| Dead Straight | Charged spin disabled | Adapt launch position and straight-line build. |
| Championship | Higher target plus one previously encountered compatible rule | Build resilience without inventing a surprise immunity. |

Bosses should challenge a build without combining constraints that make a valid starting kit physically incapable of winning. Schedule and reveal them early. Avoid hidden pin behavior.

## 11. Art, layout, animation, and sound

**Art direction:** a worn cosmic bowling alley with chunky pixel silhouettes, warm wood, cream pins, saturated teal/coral score colors, deep indigo surrounds, and drifting oil-slick color fields.

**Landscape composition:** compact run ledger at left; five Charms along the upper play area; central perspective lane; ball bag and consumables below. Keep target, current score, frames remaining, and money continuously visible.

**Portrait composition:** narrow top scoreboard, two-row Charm area with inspect expansion, tall lane, and thumb-reachable ball dock. Compress the peripheral UI rather than shrinking the lane to an unreadable thumbnail. Pause or collapse decorative effects during aiming.

**Render approach:** deliberately art-directed pixel rendering with polished geometry or sprites, expressive materials, controlled lighting, and a coherent pixel scale. Low-resolution rendering alone is not an art direction. Prototype geometry is disposable and cannot ship as final artwork. Choose the rendering technique by visual results; preserve crisp silhouettes and detailed material identity while supporting smooth motion, reflections, holographic shaders, and sophisticated effects. Validate both still frames and moving sequences at actual phone size.

**Motion specification:** gently tilting collectible tiles; crisp press states; readable ball rotation and trails; a brief impact accent; sequential pin and Charm highlights as the score counts upward. Show additions and multipliers with distinct symbols. Provide 1×/2×/4× scoring animation speed and a persistent calculation log.

**Audio:** original mellow electronic loop, tactile ball-roll rumble, material-specific pin impacts, and ascending scoring tones. Music intensity may grow with a chain; aim mode remains calm. Audio and haptics are optional.

CRT scanlines, screen curvature, chromatic separation, shake, and flashing are independently adjustable or disabled. Primary text remains sharp and legible. No copied Balatro mascot, card art, soundtrack, or Pokémon imagery is needed.

## 12. Implementation architecture

Proposed engine choice: Godot 4 for a small 3D bowling scene plus 2D UI, initially validating desktop and mobile exports. This is an architectural proposal; platform/export constraints and the exact engine version must be checked during setup.

Keep four modules separate:

- Input converts pointer/controller actions into launch position, direction, speed, and spin.
- Simulation consumes launch parameters and returns pin-state and collision events.
- Rules resolve frame categories, effects, score, economy, and progression.
- Presentation plays effects from the rule log without changing the result.

Data definitions cover balls, pins, Charms, bosses, and shop pools. Effects use documented event hooks instead of scattered item-name checks. Save run seed, rules version, RNG states, lineup IDs, inventory, money, progress, and committed throw parameters.

Use fixed physics steps and repeatability tests. A general rigid-body engine does not automatically guarantee identical outcomes across devices. Keep seeded content separate from physics; do not promise cross-platform replay fidelity until demonstrated. Start with constrained 3D physics; if near-identical launches diverge excessively, simplify collision simulation while keeping 3D visuals.

Commit a throw and save before animating it. On interruption, resume or re-simulate that committed throw rather than allowing a free reroll. Save after shop transactions and frame resolution. Handle touch cancellation, backgrounding, resizing, and save-version migration explicitly.

Define fall thresholds, settling timeout, and off-deck behavior. A pin counts once when it exceeds the fall threshold or leaves the playable deck. Still-wobbling pins resolve by the documented timeout state. Presentation cannot resurrect a scored pin.

Bound retrigger chains through explicit per-effect limits and non-recursive copy rules. Support very large scores with an appropriate numeric representation; never silently overflow. Scientific notation can display extreme scores.

## 13. Build sequence and release gates

| Stage | Deliverable | Gate before proceeding |
|---|---|---|
| 1 — Throw lab | One lane, House/Hook balls, ten Wood pins, touch/mouse input | Straight and curved shots feel intentional; test on a real phone, not just emulation. |
| 2 — Scoring slice | Two-frame match, frame rules, visible Value × Mult, four pin types, four Charms | Exact score tests pass; players understand why a frame earned its score. |
| 3 — Roguelike slice | Two Divisions, six matches, shop, save/resume, two bosses, four balls, six pin types, twelve Charms | At least three distinct viable builds; completed 10–15 minute slice. |
| 4 — Visual production | Approved representative scene, then final lane/card/item art, lighting, effects, portrait/landscape layouts, original audio, and accessibility | Meets Section 17 visual-quality gates in stills and motion on target phones; no aiming obstruction or placeholder assets. |
| 5 — Full-run alpha | Eight Divisions per League attempt, expanded catalogue, unlocks, endless mode | Target curve supports varied builds and ordinary player accuracy. |
| 6 — Release candidate | Onboarding, settings, recovery, balance pass, packaged builds | Interrupted runs recover correctly; no progression blockers or scoring exploits. |

The earlier 12–20+ week full-release estimate is withdrawn because it did not include the expanded catalogue and per-item art requirements. Planning assumptions remain approximately 1–2 weeks for the throw lab and 4–8 weeks for a small vertical slice, not commitments. Re-estimate full production after measuring actual design, implementation, art, and QA effort for a representative batch of common through legendary items.

The initial prototype excludes multiplayer, online leaderboards, user accounts, daily server challenges, and elaborate narrative. The full-release scope includes the expanded catalogue in Section 15; the prototype content counts are not release targets.

## 14. Verification and decisions

Required tests: strike/spare/open exclusivity; pin counted once across two rolls; two balls contributing to one frame; Charm ordering; standing-pin scoring; retrigger termination; special uses; rack reset; boss modifiers; seeded shop reproduction; purchase/save atomicity; and resume during a committed throw.

Run automated simulations over many content seeds using multiple shot profiles: accurate, average, and novice. Compare build win rates, shop spending, target failures, and single-item dominance. Follow with actual playtests: a mathematically balanced game can still feel unfair.

Performance targets are provisional: responsive input, approximately 60 fps on selected target phones, no long score-resolution stalls, and readable interfaces at small viewport sizes.

Risks and responses:

- Bowling accuracy dominates strategy → cap direct precision bonuses and strengthen alternative build objectives.
- Every build wants strikes → add and test standing-pin, spare, and economy payoffs.
- Chaotic collisions feel unfair → simplify physics, strengthen feedback, and reduce unexplained variance.
- Too much visual noise → stage effects, preserve silhouettes, and separate scoring from aiming.
- Runs drag → measure frame and shop times; shorten match count if the 30–45 minute target fails.
- Infinite score/economy loops → narrow retrigger scope, explicit effect limits, and automated exploit tests.

The first production decision is whether the throw lab feels good enough to support repeated play. Build that before expanding the shop or collectible catalogue.

## 15. Full-release content, cards, and procedural economy

### Requirements and scope

User requirements: substantial configurable variety; a balanced item economy; individual iconography and/or effects; collectible playing-card presentation; progressively shinier treatment for rarer and more powerful items; and a deck-builder feel. The following counts are design targets, not claims that the content has already been authored or balanced.

| Content family | Full-release target | Required differentiation |
|---|---:|---|
| Base balls | 24 | Distinct physical, tactical, or scoring behavior |
| Base pins | 32 | Scoring, positional, physical, and economic roles |
| Ball modifications | 16 | Compatible secondary behaviors |
| Pin modifications | 16 | Compatible secondary properties |
| Charms | 100 | Persistent build-defining effects |
| Consumables / tactical cards | 24 | Interventions and transformations |
| Shop upgrades | 16 | Selection, capacity, and resource efficiency |
| Lane conditions | 12 | Different shot and equipment decisions |
| Boss rules | 20 | Different constraints with visible counterplay |
| Starting kits | 10 | Distinct initial strategies and tradeoffs |

These total 270 authored definitions, including 228 item/modification definitions. Do not count color swaps or numerical upgrades as new base types. Do not claim all Cartesian combinations are legal, useful, or balanced. Each ball or pin supports at most one attached modification initially; compatibility tags exclude contradictory combinations.

The original ball, pin, Charm, and boss tables are starter designs. Remaining definitions are outstanding production work. Full release requires completed catalogue entries and assets, not just reaching a numerical target with placeholders.

### Card presentation and rarity

Every ball, pin, Charm, consumable, modification, and shop upgrade has a collectible card. Persistent pin and Charm cards remain installed; being represented by a card does not automatically make an item part of the draw pile.

| Rarity | Visual treatment | Gameplay intent |
|---|---|---|
| Common | Illustrated printed stock, matte frame | Reliable foundations |
| Uncommon | Metallic details and restrained foil | Specialized advantages |
| Rare | Holographic border and moving shimmer | Strong synergy pieces |
| Epic | Full-card holography and layered artwork | High-impact effects with meaningful requirements |
| Legendary | Individual frame, animated artwork, signature reveal | Exceptional, build-defining potential |

Shininess follows rarity consistently. Rarity indicates potential and scarcity, not that every rare card beats every common card in every build. Common pieces must remain useful alongside rare payoffs. No random cosmetic foil tier should obscure this relationship in the initial release.

Use distinct category symbols and frame geometry for balls, pins, Charms, consumables, and upgrades. Cards show name, category, rarity label/symbol, concise effect, and relevant stats or charges. Price is a shop overlay, not permanent artwork. Compatibility and detailed trigger text appear in inspection.

Holographic highlights respond to drag/tilt during inspection. Automatic shimmer is restrained; cards remain quiet during aiming and highlight when they activate. Reduced-motion mode uses static foil patterns. Labels, symbols, and patterns preserve meaning without color or animation. Do not require device-motion permission for the effect.

### Proposed deck-builder mechanics — prototype and validate

This is the current design proposal, not a confirmed requirement to randomize all equipment. Test it against direct equipment selection before locking the rules.

- Build a small draw deck of special-ball and tactical cards. Keep the ten-pin rack and five equipped Charms persistent.
- House Ball is always usable outside the deck and never occupies a hand slot.
- Standard starting deck: six reusable special-ball cards, two copies each of three starter types. Starting kits can replace these types.
- At each new frame, retain at most one card from the prior hand, discard the rest, then draw to four cards. On the first frame, draw four.
- Draw only at frame start unless an item explicitly grants a draw. The hand remains available for both rolls.
- Playing a special-ball card commits that ball to one roll and moves the card into the discard pile. Its physical and scoring effects remain recorded until frame resolution. A strike does not refund the card.
- Playing a tactical consumable removes that copy from the run deck after resolution. Allow at most one tactical card per roll initially; each specifies whether it can be played before or after a throw.
- Once per frame, the player may cycle one unplayed card: discard it and draw one. This is a limited resource, not unlimited fishing for a perfect hand.
- When the draw pile empties, shuffle the discard pile using a dedicated seeded RNG stream. Installed equipment and exhausted consumables never enter this shuffle.
- At the start of each match, recombine remaining hand, draw pile, and discard pile, then shuffle. Mid-match deck order persists across frames.
- Initial deck cap: 16 cards. Buying a card adds one copy; cap of two copies per reusable card identity initially. A full deck requires an explicit replacement or cancellation.
- Removal is a deliberate shop service with an initial prototype price of $3; selling a card removes it. Basic throws remain possible even if all deck cards are removed or exhausted.
- Persist deck order, hand, discard, exhausted cards, and RNG state in saves. Interrupted committed plays cannot be rerolled through reload.

If drawing creates frustration without useful decisions, retain the persistent equipment model and use drawing only for tactical cards. Make this decision through the vertical-slice playtest, not after producing the entire catalogue.

### Procedural generation specification

Use independent seeded streams for shops, rewards, lane conditions, bosses, and probabilistic item effects. Physics and animation must not consume shop randomness. Save all relevant states.

For each Division, select an eligible lane condition and boss using a compatibility matrix. Reveal their rules before the relevant shopping decisions. Initially allow one lane condition per match and one boss rule; avoid uncontrolled stacking. Do not repeat a boss within a standard run unless the final-boss specification explicitly permits it.

Shop generation: choose slot category, roll an eligible rarity, then select an item by its weight within that category and rarity. Remove maxed-out, duplicate-capped, and mechanically incompatible offers before sampling; renormalize remaining weights. A reroll must visibly replace the offers where the pool permits it.

Provisional ordinary-shop rarity weights: Common 55%, Uncommon 30%, Rare 12%, Epic 3%, Legendary 0%. Legendary cards come from special rewards/events initially, keeping their acquisition distinct. These are starting test parameters, not validated rates. Excluded rarities redistribute proportionally across eligible rarities.

Guarantee at least one broadly usable, affordable offer when the eligible pool contains one. Do not guarantee the exact missing piece of the player's current build. Keep selection logs for debugging pool dilution and dead shops.

Run variation comes from equipment choices, legal modifications, rack placement, Charm ordering, card draws, lane conditions, bosses, and economic decisions. Procedural generation combines authored rules; it does not invent untested abilities at runtime.

### Item economy specification

Every catalogue entry must define stable ID, category, rarity, pool weight, unlock condition, earliest Division, purchase and resale price, effect timing, effect scope, limits, charges or exhaustion behavior, downside, synergy tags, incompatibilities, and asset references. Separate run-persistent growth from between-run unlocks.

Provisional purchase bands: Common $3–5, Uncommon $5–7, Rare $7–10, Epic $10–14, Legendary reward-only. Individual pricing depends on category and expected benefit, not rarity alone. Retain the existing $3 match payout, interest cap, and increasing reroll costs only as initial simulation inputs.

Normal sales return half the actual paid price, rounded down. Free reward items have an explicit base sale value. Prevent buy/sell discounts from creating unlimited profit. Removal, modifications, consumables, and upgrades provide competing money sinks. Test whether capped interest makes saving too dominant over active investment.

Currency effects do not automatically participate in score retriggers. An effect must explicitly allow an economic retrigger and define a limit. Track gross income, net income, spend, savings, rerolls, and time to recover an investment. Especially test Gold pins: a full Gold rack could otherwise overwhelm the original $3 baseline payout.

Balance across strike, spare, standing-pin, precision, curve, retrigger, growth, and economy builds. Measure item pick rates and conditional win rates while accounting for acquisition time, rarity, and player accuracy. A high raw win rate alone does not prove an item is overpowered. Simulations identify candidates; human playtests validate comprehension and fun.

### Per-item art and effects acceptance criteria

Every base item must have an identifiable icon/card illustration, a readable small-size appearance, category and rarity markings, activation feedback, and a consistent inspection view. Balls and pins also require identifiable in-lane appearances. Physical ability changes need clear anticipation and impact feedback.

Examples: Echo uses concentric pulses; Ghost uses translucency/phasing; Fuse uses a visible ignition and one blast; Gold uses coin-shaped income feedback; Grower shows accumulating growth marks. Modifications add consistent badges or overlays without hiding base identity.

Reusable rarity shaders and shared scoring animations are encouraged, but they cannot substitute for unique item identity. Legendary art and reveals receive individual treatment. Test readability with effects off, low color discrimination, and a dense mixed-pin rack.

Maintain an asset manifest per item: card illustration, icon, in-play mesh/sprite/material where relevant, rarity treatment, activation effect, optional sound cue, and reduced-motion variant. Missing required assets block content-complete status.

### Revised production gates

1. Validate throwing and the proposed hand/cycle loop with a small representative set.
2. Author the full catalogue with explicit economy, compatibility, and visual specifications.
3. Build one complete common-to-legendary art/effect batch to measure production cost.
4. Implement and test content by build family, including interactions across families.
5. Run seeded economy/availability simulations and human playtests throughout production.
6. Reach full release only when the agreed catalogue, icons, effects, saves, and balance gates are complete. Any count reduction must be an explicit scope decision, not an unannounced substitution of prototype scope.

The following remain uncompleted: full named catalogue beyond the initial examples; final item prices and appearance weights; individual card artwork; implemented deck mechanics; and simulation/playtest validation. This document incorporates the requirements and current proposals; it does not claim those production tasks have been performed.

## 16. Persistent Career and thematic Leagues

### Evaluation and recommendation

Adopt a persistent Career built around a home bowling club and several themed Leagues. Each League is a replayable procedural campaign; one attempt at it replaces the player-facing word “run.” Wins and losses reset the temporary build, but discoveries, completed milestones, unlocked items, records, trophies, and club cosmetics persist.

Permanent rewards are a design choice, not a requirement shared by all roguelikes. The relevant distinction is between horizontal progression (more choices and challenges) and vertical progression (permanent numerical advantages). Prefer horizontal progression here: mastery and combinations should win games, without requiring repeated losses to purchase enough starting strength.

Balatro’s official FAQ documents collection unlocks, achievement-gated Jokers, deck difficulty, and challenges. Supergiant’s Hades FAQ describes permanent progression alongside difficulty modifiers and characters. These demonstrate different approaches, rather than one mandatory genre formula. Our proposed blend uses Balatro-like content unlocks with a persistent club that gives those achievements visible context.

### Terminology

| Term | Meaning |
|---|---|
| Career | Persistent profile and progress across all play |
| League | A selectable themed campaign and ruleset |
| League attempt | One fresh procedural playthrough of that League |
| Division | One of eight stages within an attempt |
| Match | One of three score challenges within a Division |
| Frame | Up to two rolls; two frames maximum per match |
| Championship | Final boss match of the League attempt |

Buttons use “Enter League,” “Resume League,” and “Try Again.” The eight stages formerly called Leagues are now Divisions; they are not eight separate selectable themes. Difficulty tiers are independent of theme and of the ten starting kits.

### Initial League roster

Launch target: three immediately playable Leagues, with three more earned through victories. All can initially use the standard eight-Division structure; themes change rule emphasis, eligible lane conditions, bosses, and selection weights, not just background art.

| League | Access | Identity and decision pressure |
|---|---|---|
| House League | Available immediately | Broad equipment access; the baseline learning and experimentation experience |
| Neon League | Available immediately | Curve and precision opportunities with visible lane variation; straight-shot alternatives remain viable |
| Salvage League | Available immediately | Material interactions, modifications, and repair/replacement decisions |
| Royal League | Win House League | Position-sensitive scoring, valuable targets, and demanding clear objectives |
| Spectral League | Win Neon League | Phasing, echoes, and limited retriggers; strict event-order clarity |
| Foundry League | Win Salvage League | Heavy, fragile, and explosive interactions with explicit tradeoffs |

Names and exact rules are proposals. Six themes are a full-release scope addition; they reuse the planned item catalogue rather than silently multiplying it. Each newly opened League launches with a small thematic starter package, allowing a new strategy immediately.

Do not require completion of all three opening Leagues before any new League appears. The branching unlock structure gives players agency when one theme does not suit them. All three initial Leagues must be winnable with their initially accessible content.

### Three complementary unlock paths

1. **First boss victories:** defeating a named boss for the first time unlocks one thematic item or small predefined package for future attempts. The record is global by boss ID, so repeated encounters do not grant duplicates. Bank the unlock immediately even if the attempt later fails.
2. **League championships:** first victory opens the corresponding advanced League and a starting-kit option or themed package. Later victories award difficulty medals, mastery achievements, records, or cosmetic trophies rather than repeat copies of the same unlock.
3. **Mastery objectives:** visible goals such as converting a number of spares, completing a controlled curved shot, or successfully using several pin materials unlock additional cards. Mix single-attempt feats with cumulative objectives so losing players can make meaningful progress.

Unlocking means eligible to appear, not automatically owned or equipped. Existing saves keep their current content-pool snapshot; unlocked gameplay content begins appearing in the next attempt. A result notification states this clearly.

Initial allocation targets: 12 of 24 balls and 16 of 32 pins available from the start. Allocate the remaining 12 balls as six boss unlocks and six championship/mastery unlocks; allocate the remaining 16 pins as eight boss unlocks and eight championship/mastery unlocks. Packages may distribute these across League branches. These are availability targets, not additional content beyond Section 15.

For the 100 Charms, initially target 60 available and 40 unlocked through progression. Unlock a balanced mixture of foundational, specialist, and high-rarity options; do not lock basic economy tools or essential boss counters behind the challenge they are needed to beat. Rare starting-pool items can still exist; availability and rarity are separate axes.

Every unlock must declare its prerequisites and accessible alternative means of progress where appropriate. Validate the prerequisite graph for cycles and unreachable nodes. Never require a locked item to unlock itself.

### What persists and what resets

| Persists after defeat | Resets for the next attempt |
|---|---|
| Unlocked cards, Leagues, and starting kits | Current deck, hand, discard, and consumables |
| Boss victories and completed unlock objectives | Purchased pins, modifications, and equipped Charms |
| Cumulative mastery progress | Money, interest, and shop upgrades |
| Collection discoveries and item records | Temporary item growth and technique levels |
| Trophies, difficulty medals, and club cosmetics | Current match/Division progress |
| Selected accessibility preferences | Attempt-specific lane conditions and RNG state |

Distinguish collection states: Locked, Available, Discovered, and Mastered. The career binder preserves item art and history; it does not let the player import previously acquired cards into a new attempt for free.

### A persistent home that shows progress

Use a compact Clubhouse screen: trophy shelf, holographic collection binder, League board, mastery goals, and personal bests. Restore or decorate the club through milestones—new sign, lane trim, trophy cases, card backs, and background music options. These have no scoring advantage.

A lightweight “take the club from local alley to champion” premise can connect the activity without requiring an expensive narrative campaign. Brief rival/boss introductions and championship acknowledgments are sufficient initially.

After an attempt, show its ending, furthest Division, a concise explanation of the final score, newly unlocked items, and progress toward at most three tracked goals. Include a direct “Enter League” action. Record useful achievements without promising that every ten-second loss earns a reward.

Avoid a second spendable progression currency initially. Boss rewards and explicit milestones already provide persistence; another currency risks grinding and obscures why items unlock. Cosmetic milestones can remain available after the gameplay catalogue is complete.

### Fairness, pool dilution, and difficulty

Unlocks should not inflate the pool until functional builds disappear. Preserve Section 15’s category and rarity weights, then select a broadly useful or specialist role within each eligible category using tested weights. Provide stable opportunities to acquire core scoring, economy, and counterplay tools as specialist options grow.

Thematic Leagues bias specialist selections without excluding all cross-theme combinations. Keep some broad-pool offers to preserve surprising synergies. Do not provide unrestricted pre-attempt bans that let players remove every unwanted card and manufacture a guaranteed build; any optional curated pools would need explicit rules and separate comparison labels.

Winning a League opens an optional harder tier for that League. Harder tiers initially award medals/cosmetics and challenge records, not indispensable gameplay items. This keeps the core catalogue accessible without requiring mastery of the highest difficulty.

No permanent global +score, +starting cash, or +power upgrades in the initial design. Starting kits may offer advantages with explicit tradeoffs. Accessibility assists remain settings, not rewards that struggling players must grind to unlock.

Normal unseeded attempts advance gameplay unlocks. Practice/custom-seed modes show discoveries and practice records but do not grant gameplay unlocks, preventing a repeatable known seed from trivializing progression. Show this rule before starting. This is a proposed policy to validate, not a genre requirement.

### Persistence and validation requirements

Store Career separately from attempt saves. Give each unlock and milestone a stable ID. Record boss/match completion and resulting career awards atomically; reloading cannot duplicate rewards or erase a banked first victory. Version and migrate the profile as the catalogue changes.

Acceptance tests: lose after unlocking a boss reward and retain it; restart and see it eligible in the next attempt; confirm existing attempt pools do not mutate; verify championship branches; ensure no repeated first-clear rewards; prevent circular prerequisites; and verify all initial Leagues have adequate starting counters.

Measure time to first unlock, progress for losing players, repeated-boss farming, objective-driven bad play, shop usefulness as collection size grows, and completion fatigue. If optimal progression is deliberately losing early, change the rewards. Keep cosmetic rewards flowing without extending the gameplay unlock grind indefinitely.

This section is a proposed strategy incorporated into the plan. League names, individual unlock assignments, and exact mastery thresholds remain to be authored and tested. It supersedes the earlier minimal between-run unlock paragraph and adds explicit production scope for the Clubhouse, Career profile, six themes, progression UI, and prerequisite validation.

## 17. Non-negotiable visual quality

### User requirement

Pixel-based rendering is an aesthetic choice, not a visual shortcut. The game must have beautiful, dynamic, high-quality visuals and effects. Balatro is the quality and presentation benchmark. Generic block shapes, crude icons, flat recolors, or a low-resolution filter over unfinished assets do not satisfy this requirement.

Visual quality is a core production discipline and release gate, not an optional polish pass after mechanics. A functional prototype is explicitly not representative of release quality. Do not describe prototype visuals as finished simply because they are pixelated.

### Art direction and execution standards

- **Crafted artwork:** individual composition, strong silhouettes, intentional pixel clusters, controlled edge treatment, thoughtful palettes, dimensional shading, and recognizable material detail. Pixel scale must remain coherent across the lane, objects, cards, and interface.
- **Beautiful environments:** layered depth, authored lane surfaces, readable reflections, atmospheric lighting, animated signage, and restrained ambient motion. Each League has a cohesive visual identity beyond a background recolor.
- **Premium collectible cards:** original item illustrations, detailed frames, legible typography, material depth, responsive tilt, and convincing foil/holographic treatments. Rare cards should feel special through composition, material, and motion, not merely extra particles.
- **Expressive equipment:** balls visibly rotate and communicate material, weight, and ability; pins have distinctive surfaces, impact responses, and readable upright/fallen states. Silhouettes and markings remain identifiable within a mixed rack.
- **Fluid motion:** polished easing, anticipation, follow-through, secondary motion, and responsive transitions. A pixel aesthetic does not require choppy animation. Intentional held frames must be a stylistic choice, not a performance defect.
- **Layered effects:** combine authored trails, impact accents, lighting responses, material-specific particles, distortion where appropriate, and synchronized sound/haptics. Each layer has a purpose and a controlled lifetime.
- **Dynamic interface:** tactile card handling, responsive hover/press states, smooth dealing and sorting, satisfying pack reveals, and clear score-chain choreography. Interface transitions must feel as deliberate as the bowling animation.

### Signature effect briefs

| Moment | Required visual direction |
|---|---|
| Charged curve throw | Ball rotation and a directional energy trail build with spin; launch smoothly transfers that energy into the rolling motion. |
| Heavy impact | Brief local impact accent, convincing pin displacement, material particles, and restrained camera response communicate mass. |
| Echo activation | A controlled ring/pulse connects the triggering ball or card to its retriggered target, then resolves into score feedback. |
| Ghost ability | Layered translucency and a coherent phase trail show the exact transition through a pin and return to solidity. |
| Holographic card inspection | Directional foil response changes with tilt, retaining artwork contrast and readable text. |
| Legendary reveal | Distinct anticipation, frame/art reveal, lighting accent, and short signature animation with a skip option. |
| Large scoring chain | Clearly ordered card and pin activations, escalating tonal and visual intensity, and a satisfying final total; avoid simultaneous unreadable flashes. |
| Championship victory | League-specific celebration, premium trophy/card presentation, and a smooth transition to persistent Career rewards. |

These briefs require bespoke execution within a shared effects system. Reusing shaders and animation components is acceptable; making every ability the same burst in a different color is not.

### Readability and restraint

The visual hierarchy is ball/pins and aiming first, actionable cards second, atmosphere third. Effects must communicate what happened without hiding the next decision. Reserve maximum intensity for exceptional events; continuous spectacle makes rare moments feel ordinary.

Keep typography crisp. Bloom must not erase pixel silhouettes or wash out card text. CRT treatments cannot conceal weak artwork. Avoid conflicting pixel densities, blurry scaling, accidental texture filtering, and generic UI panels that clash with the art direction.

Reduced-motion and reduced-flash settings preserve composition, material identity, and meaningful feedback. Performance reductions remove secondary particles or expensive optional layers before compromising core artwork or input responsiveness. They are not permission to ship an unfinished default presentation.

### Visual production workflow and acceptance gates

1. Establish an art bible with palette families, pixel scale, typography, material references, lighting rules, motion language, and category/rarity treatments.
2. Produce one representative final-quality scene early: lane and environment, mixed pin rack, distinctive ball, a hand of cards across rarity levels, and finished HUD. Review actual-size captures, not only enlarged art.
3. Build a representative motion sequence covering aim, spin, throw, impact, ability activation, score resolution, card reveal, and return to decision-making. A good still image alone is insufficient.
4. Obtain user review of that concrete visual target before scaling art production across the catalogue. This is a design checkpoint, not a requirement to pause routine implementation or prototype work.
5. Expand through reusable art and effects systems while preserving item and League identity. Track final art separately from mechanical implementation.
6. Verify native-size portrait/landscape readability, real-device frame pacing, transitions, effect overlap, and reduced-motion variants. Review the weakest assets and effects, not just the best showcase shot.

Release blockers: placeholder or weak final artwork; unrecognizable item icons; flat recolors substituting for promised unique identity; incoherent pixel scale; stuttering throws; effects obscuring pins or text; broken rarity treatments; unfinished transitions; or quality that fails the approved representative scene standard.

Full production estimates must budget for dedicated art direction, asset iteration, shaders, animation, VFX, technical integration, and visual QA. Do not silently reduce these requirements to preserve an earlier schedule or content count.

## 18. Bosses as named rivals — approved direction

Each boss is a named rival who represents a signature lane challenge. The player defeats that rival by reaching or exceeding a posted score within the match's frame budget while obeying the displayed boss rules. Rivals do not take simulated bowling turns. The opponent has a character identity and reactions, while the mechanical contest remains a score objective with a meaningful rule change.

### Encounter structure

1. Reveal the upcoming rival, posted target, signature rule, and first-clear reward before the player commits to relevant shop decisions. The target is fixed for that match; it does not secretly adjust to player performance.
2. Introduce the rival through a brief, skippable animated portrait and entrance, with their name and challenge plainly displayed.
3. Transform the lane's lighting, materials, signage, and atmosphere to express the rival's identity and active rule. Preserve the player's pin identities and effects underneath any encounter treatment.
4. During play, use short portrait reactions to major scoring chains, strikes, missed opportunities, and near-victories. Reactions never pause input, obscure the rack, or imply an unannounced mechanical attack.
5. On success, play a distinct defeat reaction and victory transition, bank the first-clear Career reward immediately, then continue to the shop or championship results. On failure, show the unmet score and active rule clearly, preserve earned Career progress, and offer retry/navigation.

The boss should test both scoring strength and adaptation. Announce restrictions early; do not increase difficulty solely by raising the target. The existing two-frame match budget remains the default unless an explicitly displayed encounter rule changes it.

### Initial rival concepts

Names are working character concepts; the named-rival format is approved. These characters represent existing boss rules, not additional boss mechanics beyond the 20-rule content target.

| Rival | Signature challenge | Presentation |
|---|---|---|
| Slick | Oil Slick: hook strength reduced 50% | Iridescent oil patterns, reflective lane highlights, and a smug portrait that shifts to surprise as the player adapts. |
| Iron Mae | Heavy Set: pin masses increased 50% | Industrial lighting and reinforcement overlays on pins, preserving material markings; weighty impact feedback and a visibly formidable rival. |
| The Custodian | Clean Sweep: only strikes/spares bank points | Pristine surfaces, a sweeping spotlight, precise visual motifs, and a composure-breaking defeat animation. |
| The Surveyor | Dead Straight: charged spin disabled | Geometric alignment graphics, rigid lighting patterns, a clearly disabled spin indicator, and exacting character gestures. |

### Required character assets and behavior

Every rival requires an original recognizable portrait, idle animation, entrance, confident reaction, impressed/threatened reaction, defeat reaction, thematic lane treatment, and short written introduction. Dialogue can be text-only initially; voice acting is not required. Deliver these to the visual standard in Section 17, including reduced-motion alternatives.

Use a small event-driven reaction system with cooldowns and precedence so a score chain cannot spam multiple reactions. Character presence should strengthen the feeling of a contest without forcing the player to watch repetitive cutscenes. Repeated introductions are skippable and can be shortened automatically after first encounter.

The HUD shows rival name, target score, current player score, remaining frames, and an inspectable rule badge. Keep terminology consistent: meeting the target defeats the rival; there is no hidden opponent score simulation or separate health bar.

### Integration and acceptance

Use stable boss/rival IDs to connect appearance, rule, unlock reward, first-clear status, trophy, and collection record. A rival may scale its target across Divisions or difficulties, but remains recognizable through its signature rule and presentation. Final championships can use a League champion with an explicitly authored compatible rule set.

Add character production, reaction animation, encounter transitions, and thematic lane integration to the production budget. Validation covers advance rule visibility, target stability, unobstructed aiming, correct victory detection, skippable scenes, reduced-motion behavior, and first-clear rewards surviving a later loss or reload.

## Sources

[1] Balatro official FAQ: https://www.playbalatro.com/faq
Undated live page; reviewed October 25, 2026. Run structure, Joker roles, Tarot transformations.

[2] Playstack — Balatro: https://www.playstack.com/games/balatro/
Undated publisher page; lists the February 20, 2024 release. Reviewed October 25, 2026. Presentation, upgrade families, and game description.

[3] Rogueliker — direct LocalThunk interview: https://rogueliker.com/balatro-interview/
Published March 7, 2024. Familiarity, design evolution, balance, and risk mitigation.

[4] Game Design Lab — Balatro scoring engine: https://teemo.dev/game-design/balatro/systems/scoring-engine-chips-mult/
Community documentation; reviewed October 25, 2026. Used for broad scoring structure, not as a specification to clone.

[5] Pokémon GO Help Center — Finding & Catching Wild Pokémon: https://niantic.helpshift.com/hc/en/6-pokemon-go/faq/102-finding-catching-wild-pokemon/?l=en
Live help page; reviewed October 25, 2026. Hold/fling, shrinking target, and circular curveball gesture.

[6] LocalThunk — developer blog: https://localthunk.com/
Reviewed October 25, 2026 alongside a recent-change search. Upcoming update details are outside the dependency scope of this plan.


[7] Supergiant Games — Hades FAQ: https://www.supergiantgames.com/blog/hades-faq/
Published December 7, 2018; live page reviewed October 25, 2026. Used for the contrast between permanent progression and difficulty systems; not as evidence that all roguelikes require stat progression.
