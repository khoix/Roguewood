# AV-FIX1 — Spare Jar transparency

State: DONE — implementation and affected verification, 2026-11-23. Effort High.
Implementation checkpoint f61cb0a; coordinator 329447e merged by 489c007.
The ledger conflict kept both sections. All three UI-33b coordinator ball shaders
are unchanged. Seven other cards were already matted by the coordinator.

## Delivered

Spare Jar uses a regenerated RGBA source, preserving its brass rim, green glass
and two copper coins. An initial pass added external haze; a second generation
removed it. The original sheet remains unchanged. The generated PNG is copied
without pixel edits; card, icon and reduced views share an AtlasTexture region.
The counted in-play jar uses its existing icon hook. No catalogue, effects,
sound or rule changes. Exact prompts and SHA are in docs/art/briefs/AV-FIX1*
and ASSET-LEDGER.md. Central glass alpha is 4/255; sampled mouth/background alpha
is zero. The transparency guard now has no KNOWN_OPAQUE exceptions.

## Native evidence

JAVFIX1B/JAVFIX1BB drive the actual Binder preview; JAVFIX1S/JAVFIX1SB play the
opener and reroll to a real Spare Jar offer. The shop fixture grants $2000 after
the opener, as the original item journeys do. It injects no offers or unlocks.
The before variants load the retained original atlas region only in memory,
with an explicit BEFORE ART log. They are original-art specimens in today's
native UI, not screenshots of an old game build. They change no shipping files
or Career progress. Each capture awaits RenderingServer.frame_post_draw.

All eight comparisons were visually reviewed: portrait/landscape, Binder/shop,
before/after. The new jar lets the different panel/card backgrounds show through
its mouth and central glass without a rectangle or halo. Contact sheets also
show icon, reduced and counted variants. The coordinator's seven mattes were
reviewed in the three House contact sheets; no refinements were needed.

## Capture index

- artifacts/av-fix1/binder/{before,after}/rendered/binder_{portrait,landscape}.png
- artifacts/av-fix1/shop/{before,after}/rendered/shop_{portrait,landscape}.png
- artifacts/av-h3-b/contact/rendered/{contact,motion,counted}.png
- artifacts/av-h4-{a,b}/contact/rendered/contact.png
- artifacts/e18-c10/rendered/: native growth, paid cue, inventory, sale/rebuy.

Four native journeys are registered add-only in qa.py and CI's art shard;
artifacts/av-fix1 is uploaded with journey evidence. Captures are never committed.
The before fixtures are tool-only and do not ship into game flows.

## Verification

Pinned Godot 4.5.2, Linux llvmpipe, isolated Xvfb displays, normal graphics detail.
Merged-tree unit/content/physics, J03C10 headless/rendered, all three House
contacts headless/rendered and all four native comparison journeys in both
modes pass. J11 headless/rendered pass. Its first parallel rendered run hit
PERF-1b's 60 ms worst-frame budget (79.3 ms; average 0.031 ms); the isolated
rerun passed in 48 s with the budget and production code unchanged. Results/logs are preserved under
artifacts/wave14/resume-20261123/. No physical-phone or full-local-matrix claim.

## Exact resume

AV-FIX1 is complete. Finish the separate AV-N4/N5/UI-A6 merge verification and
push for the full CI gate; CI status is recorded separately from this local
implementation result. Next art item: UI-A9-H, High recommended, following its
brief and UI-20 contract. No AV-UI1 or Wave 15 work is authorized here.
