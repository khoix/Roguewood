# Historical review patches

`e13-art-completeness.patch` is superseded. It was not applied by Codex: the owner
reserved that correction for Claude. Coordinator commit `5ecc1f0`, merged as
`1173592`, supplied the correction. The full unit suite passes with final art flags.

`e16-missing-art-fixture.patch` was applied with explicit owner authorization in
Wave 2. It keeps the missing-art fallback assertion and uses an intentionally
missing ID now that trophy.house has final artwork. Do not reapply it.
