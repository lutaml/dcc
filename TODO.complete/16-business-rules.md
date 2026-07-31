# 16 — Business rule validators (P1)

**Status:** PARTIAL

## Gaps
- Only two rules ship: `MainSignerSingle`
  (`lib/dcc/validate/business_rules.rb:71`, the renamed
  `RespPersonsMainSigner`) and `UniqueIdentifierPresent` (line 94).
- `MandatoryLanguageCoverage`, `StatementRefType` and `PreviousReportHash`
  do not exist.

## Goal
Ruby-side semantic checks beyond what Schematron covers — cross-section consistency, signature presence, template coherence.

## Files
- `lib/dcc/validate/business_rules.rb` — service class + rule registry.
- Optional: `lib/dcc/validate/business_rules/*.rb` per rule (template consistency, item identification uniqueness, signer coverage, certificate expiration, etc.).

## Design notes
- Examples:
  - `RespPersonsMainSigner` — exactly one `respPerson` has `mainSigner=true`. Shipped as `MainSignerSingle`.
  - `MandatoryLanguageCoverage` — every `dcc:content` element has the mandatory language code.
  - `StatementRefType` — every `statement` with `refType="conformity"` has a `declaration` child.
  - `PreviousReportHash` — if `previousReport` present, all hash fields populated.

## Dependencies
- 12.

## Verification
- Spec per rule with one positive and one negative fixture.
