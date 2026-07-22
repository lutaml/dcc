# 37 — Implement stub Schematron rules (P1)

**Status:** COMPLETED

## Goal
Four Schematron rules currently return `[]` unconditionally. Implement
the actual PTB semantics:

- `AdministrativeDataCompleteness`: ensure `dccSoftware`, `coreData`,
  `items`, `calibrationLaboratory`, `respPersons`, `customer` are present
- `UncertaintyConsistency`: value list length must equal uncertainty list length
- `UnitFormatCheck`: SI units have no whitespace
- `NonSiDeclaration`: non-SI units (`|`-prefixed) require declaration

## Files
- `lib/dcc/validate/schematron/rules/administrative_data_completeness.rb`
- `lib/dcc/validate/schematron/rules/uncertainty_consistency.rb`
- `lib/dcc/validate/schematron/rules/unit_format_check.rb`
- `lib/dcc/validate/schematron/rules/non_si_declaration.rb`

## Verification
- New specs with crafted fixtures exercising each rule's violation
- All existing specs still pass
