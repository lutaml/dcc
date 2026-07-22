# 09 — Dcc::V3 wrappers (P1)

**Status:** COMPLETED

## Goal
Thin wrapper classes for every DCC element under `Dcc::V3::*`, including v3 extras (`refId`, `refType`, v3.4.0-rc.2 features as optional attributes), registering in `:dcc_v3`.

## Files to create
- `lib/dcc/v3.rb` — module body with `extend Dcc::VersionedParser`, `ROOT_ELEMENT_TAG`, autoloads, eager-register.
- `lib/dcc/v3/configuration.rb` — `CONTEXT_ID = :dcc_v3`. Also pre-registers a `:dcc_v3_4` substitution context for v3.4.0-rc.2.
- `lib/dcc/v3/namespace.rb` — `Dcc::V3::Namespace = Dcc::Namespace::Dcc` with version "3.3.0" (overridable to "3.4.0-rc.2" via `Dcc::V3::Configuration.custom_models=`).
- `lib/dcc/v3/common_elements.rb` — base class adding `refId`, `refType` attributes + `lutaml_default_register` returning `:dcc_v3`.
- One wrapper per element under `lib/dcc/v3/` (mirrors `lib/dcc/v2/`).

## Design notes
- V3-specific modules (`V3Extras`) add the `refId`/`refType` attributes shared by most types.
- V3.4.0-rc.2 features (`measurands`, `richContentType`, `reportAmendedSubstituted`, `relativeUncertainty`, `positionCoordinates`, `performanceLocation`) live in `Dcc::Base::*` modules as optional attributes — V3 wrappers can ignore them.
- `ds:Signature` element on root (new in 3.4.0) is an optional collection attribute on `DigitalCalibrationCertificate`.

## Dependencies
- 07 (DCC base modules).

## Verification
- `Dcc::V3.parse(fixture_xml_v3_3_0)` returns a `Dcc::V3::DigitalCalibrationCertificate`.
- `dcc.administrative_data.items.first.ref_id` available on V3 classes.
- V3.4 fixture parses with `Dcc.parse(xml, context: :dcc_v3_4)` without errors.
