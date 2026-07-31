# 40 — Wire Dcc::V2::Quantity to D-SI v1 (P2)

**Status:** COMPLETED

## Goal
`Dcc::V3::Quantity` already wires D-SI v2 elements (`:real`, `:hybrid`,
`:realListXMLList`, etc.) as typed collection attributes. Do the same
for `Dcc::V2::Quantity` against D-SI v1.

## Files
- `lib/dcc/v2/quantity.rb` — declare D-SI v1 element attributes in a
  single `xml do` block (same pattern as V3)

## Verification
- Parse a v2 fixture with embedded D-SI quantities
- (Not covered: the only spec naming `Dcc::V2` is `spec/dcc_spec.rb`, asserting
  `parser_for(2)` returns the module. Nothing reaches a v2 quantity.)
