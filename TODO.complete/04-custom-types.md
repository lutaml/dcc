# 04 — Custom types (P0)

**Status:** COMPLETED

## Goal
Six `Lutaml::Model::Type::Value` subclasses that encode DCC/D-SI-specific XML constraints.

## Files created
- `lib/dcc/type.rb` — autoloads.
- `lib/dcc/type/iso_country_code.rb` — `IsoCountryCode` (xs:string pattern `[A-Z]{2}`).
- `lib/dcc/type/iso_language_code.rb` — `IsoLanguageCode` (`[a-z]{2}`).
- `lib/dcc/type/si_unit.rb` — `SiUnit` (no whitespace; full siunitx validation happens in Schematron).
- `lib/dcc/type/decimal_xml_list.rb` — `DecimalXmlList` (whitespace-separated BigDecimal list ↔ Array).
- `lib/dcc/type/base64_binary.rb` — `Base64Binary` (text ↔ binary ASCII-8BIT String).
- `lib/dcc/type/schema_version.rb` — `SchemaVersion` (semver string with major/minor/patch accessors).

## Design notes
- All raise `Lutaml::Model::Type::InvalidValueError` on bad input so the framework surfaces them as validation errors.
- `cast` and `serialize` are inverse pairs; specs cover round-trip for each.

## Verification
- One spec per type: valid input → cast/serialize round-trips; invalid input → raises.
