# 02 — Namespace classes (P0)

**Status:** COMPLETED

## Goal
Five `Lutaml::Xml::Namespace` subclasses for the XML namespaces DCC documents use.

## Files created
- `lib/dcc/namespace.rb` — autoloads the five subclasses.
- `lib/dcc/namespace/dcc.rb` — `Dcc::Namespace::Dcc` for `https://ptb.de/dcc`, imports Si + MathMl + Dsig.
- `lib/dcc/namespace/si.rb` — `Dcc::Namespace::Si` for `https://ptb.de/si`, imports Qudt.
- `lib/dcc/namespace/math_ml.rb` — `ml` prefix for W3C MathML.
- `lib/dcc/namespace/dsig.rb` — `ds` prefix for W3C XMLDSig.
- `lib/dcc/namespace/qudt.rb` — `qudt` prefix for QUDT vocabulary.

## Design notes
- `uri_aliases` accepts the legacy `https://ptb.de/dcc.xsd` form so old fixtures round-trip.
- `schema_location` points to the latest version; per-version overrides live in `Dcc::V2::Namespace`, `Dcc::V3::Namespace`, `Dcc::Si::V1::Namespace`, `Dcc::Si::V2::Namespace`.
- DCC `imports` Si + MathMl + Dsig because the XSD declares those `<xs:import>`s.

## Verification
- Unit spec: instantiate each namespace class and assert URI, prefix_default, imports list.
