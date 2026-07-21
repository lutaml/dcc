# 22 — Inspection report (P2)

**Status:** PENDING

## Goal
Produce a human-readable summary of a DCC: counts, signature status, validity, languages, key identifiers.

## Files
- `lib/dcc/inspect.rb` — autoloads.
- `lib/dcc/inspect/report.rb` — `Dcc::Inspect::Report.call(dcc)` returns a `Report` model with `to_s` (tty-table formatted), `to_json`, `to_yaml`.

## Design notes
- Report sections: Identity (schemaVersion, uniqueIdentifier, IDs), Administrative (calibration lab, customer, signers, dates), Measurement (count of results, quantities, units), Signatures (present, valid?), Validity (last XSD/Schematron result if cached).
- Used by `dcc inspect` CLI command.

## Dependencies
- 12.

## Verification
- `Dcc::Inspect::Report.call(dcc).to_s` includes uniqueIdentifier, item count, measurement result count.
