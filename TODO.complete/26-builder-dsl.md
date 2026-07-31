# 26 — Builder DSL (P2)

**Status:** PARTIAL

## Gaps
- `lib/dcc/builder/dsl.rb` is an empty placeholder; the DSL lives on
  `Session`.
- `Session` has no `result`, `quantity` or `data` methods, so a built DCC
  cannot contain measured values.
- `spec/dcc/builder/builder_spec.rb` has three examples, not coverage of
  every DSL method.

## Goal
Programmatic DCC creation: `Dcc.build(version: 3) { administrative_data { ... } }` returns a `Dcc::V3::DigitalCalibrationCertificate` instance ready to serialize.

## Files
- `lib/dcc/builder.rb` — autoloads.
- `lib/dcc/builder/session.rb` — builder session tracking the current container.
- `lib/dcc/builder/dsl.rb` — DSL methods (`administrative_data`, `core_data`, `items`, `item`, `measurement_results`, `result`, `quantity`, etc.).
- No `lib/dcc/builder/error.rb` was created; the builder raises `Dcc::BuilderError` from `lib/dcc/error.rb`.

## Design notes
- DSL is evaluated in `Session#instance_eval` so blocks feel natural.
- Each DSL method instantiates the right model class and pushes it onto the parent's collection.
- Required-field validation at `build` exit (raise `BuilderError` if mandatory fields missing).

## Dependencies
- 09, 11.

## Verification
- Build a minimal DCC, serialize, re-parse, assert key fields match.
- (Not covered: `spec/dcc/builder/builder_spec.rb` has three examples and does not
  reach every DSL method. See the gaps above.)
