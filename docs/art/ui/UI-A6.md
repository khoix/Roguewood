# UI-A6 — House pin deck

Plan before authoring: original procedural walnut grain, recessed panels, brass
rails and diamond inlays. Static unshaded shader; no geometry, lights, bodies,
shapes, physics materials or lane surface changes. No external sources.

Bindings: each House/Neon manifest has a top-level pin_deck material path;
missing entry leaves existing walls alone. Neon material stays byte-identical.
Existing three visible kickback/cushion meshes receive the finish. Inspect their
pit-facing edges and upper faces in live rolling captures.

Evidence: new JUIA6 extends the full House League journey, checks all nine stages
and captures Division2 feature, boss and Championship in both orientations and
rolling views. J22L01/J22L02 and their art journeys, unit/content/physics and
protected scoring/presentation regressions follow. No captures committed.

Owner explicitly approved correcting neon_pin_deck_art_test.gd, including clearing
both presentation markers before checking the missing-entry fallback.
