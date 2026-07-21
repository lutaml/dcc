# 03 — ContextConfiguration + VersionedParser (P0)

**Status:** COMPLETED

## Goal
Port the registry-aware per-major-version pattern from plurimath/mml so each version module (`Dcc::V2`, `Dcc::V3`, `Dcc::Si::V1`, `Dcc::Si::V2`) has its own `Lutaml::Model::TypeRegistry` and substitution context.

## Files created
- `lib/dcc/context_configuration.rb` — `Dcc::ContextConfiguration` mixin: `register_model`, `create_context`, `populate_context!`, `custom_models=`.
- `lib/dcc/context_options.rb` — `Dcc::ContextOptions` normalizer for `context:`/`register:` options. `UNSPECIFIED_CONTEXT` sentinel.
- `lib/dcc/versioned_parser.rb` — `Dcc::VersionedParser` mixin: `.parse(input, context:, register:)` resolves the root class via `Lutaml::Model::GlobalContext.resolve_type(ROOT_ELEMENT_TAG, context_id)`.

## Design notes
- Each version module must define `ROOT_ELEMENT_TAG` constant (`"digitalCalibrationCertificate"` for DCC, `"real"` for D-SI v1/v2 single-quantity parse, etc.) and a `Configuration` submodule with `CONTEXT_ID`.
- `populate_context!` is idempotent and rebuilds from `registered_models` — essential for spec isolation.

## Verification
- Unit spec: register a fake model in a derived context, parse a tiny XML, assert the class is used.
