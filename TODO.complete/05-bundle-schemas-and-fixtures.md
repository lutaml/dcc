# 05 — Bundle XSD/Schematron resources + fixtures (P0)

**Status:** COMPLETED

## Goal
Ship the 12 DCC XSDs, 6 D-SI XSDs, QUDT, Schematron, and xmldsig-core schemas with the gem. Copy PTB example documents into `spec/fixtures/` for round-trip testing.

## Files created
- `lib/dcc/schema.rb` — `Dcc::Schema.path`, `.exists?`, `.read` API + autoload of `Version`.
- `lib/dcc/schema/version.rb` — `DCC_ALL`, `DCC_LATEST`, `DSI_ALL`, `DSI_LATEST`, `resolve_dcc(version, xml:)`, `resolve_dsi`, `detect_from_xml`, `major(v)`.
- `lib/dcc/schema/resources/dcc/v{2.1.0,...,3.3.0}/dcc.xsd` — 12 DCC XSDs.
- `lib/dcc/schema/resources/dsi/v{1.0.1,...,2.2.1}/SI_Format.xsd` — 6 D-SI XSDs.
- `lib/dcc/schema/resources/qudt/qudt.xsd`.
- `lib/dcc/schema/resources/schematron/dcc.sch`, `dcc.svrl`.
- `lib/dcc/schema/resources/xmldsig/xmldsig-core-schema.xsd`.
- `spec/fixtures/ptb/` — PTB dcclib test resources (valid.xml, invalid_*.xml, custom.*, certs/).
- `spec/fixtures/dcc_examples/` — DCC XSD repo examples (example.xml, siliziumkugel.xml, excel_viewer_example.xml).
- `spec/fixtures/dsi_examples/{BRONZE,SILVER,GOLD,PLATINUM,IMPROVABLE,NOT_PASSED}/` — D-SI examples by tier.

## Design notes
- Schemas live under `lib/` so they ship with the gem via `git ls-files` in gemspec.
- Version directory naming: `dcc/v3.3.0/dcc.xsd` (not `dcc/v3.3.0.xsd`) — leaves room for future multi-file schemas.
- The Python `__init__.py` files were excluded.

## Verification
- `Dcc::Schema.exists?("dcc/v3.3.0/dcc.xsd")` → true.
- `Dcc::Schema::Version.resolve_dcc("auto", xml: File.read("spec/fixtures/ptb/valid.xml"))` → `"3.3.0"`.
