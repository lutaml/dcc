# 11 — Wire DCC ↔ D-SI (P1)

**Status:** COMPLETED

## Goal
Connect `dcc:quantityType` to D-SI quantity classes and finalize the `dcc:dataType` choice model.

## Files to modify
- `lib/dcc/base/quantity.rb` — declare six optional collection attributes (`real`, `complex`, `constant`, `real_list_xml_list`, `complex_list_xml_list`, `hybrid`) each typed to `Dcc::Si::V2::*`. Use the version-appropriate Si class via the active context.
- `lib/dcc/base/data.rb` — wire `choice min: 0, max: nil` containing all six data variants. Verify `xs:choice maxOccurs="unbounded"` interleaving works; if not, fall back to multiple optional collection attrs with `ordered`.
- `lib/dcc/v3/quantity.rb` — make sure the type-registry lookup for child `si:real` etc. dispatches to `Dcc::Si::V2::Real` in `:dcc_v3` context.
- `lib/dcc/v2/quantity.rb` — same for V1 (`Dcc::Si::V1::*`).

## Design notes
- The `Dcc::Si::*` namespaces are imported into both `:dcc_v2` and `:dcc_v3` contexts via fallback chain.
- If `polymorphic:` dispatch by element name fails (Risk R2), pivot to Option B (per-element attribute). Spec covers both.
- The choice container's `quantity` attribute accepts any D-SI quantity; serialization must round-trip the concrete element name.

## Dependencies
- 09 (Dcc::V3 wrappers), 10 (D-SI model).

## Verification
- PTB `valid.xml` parses and round-trips with full D-SI quantity tree intact.
- Spec: parse `dcc:quantity` containing `si:hybrid`, navigate `dcc.measurement_results.first.results.first.data.quantities.first.real.first.value` returns a BigDecimal.
