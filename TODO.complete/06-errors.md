# 06 — Error hierarchy (P0)

**Status:** COMPLETED

## Goal
Structured error classes for every failure mode the gem can encounter.

## Files created
- `lib/dcc/error.rb` — base `Dcc::Error < StandardError` plus `Dcc::Error::*` subclasses:
  - `ParseError` — malformed XML / encoding issues.
  - `ValidationError` (base, carries `issues:`) + `SchemaError` subclass.
  - `SignatureError`, `ConversionError`, `ExtractionError`, `TransformError`.
  - `UnknownVersionError`.
  - `BuilderError`.
  - `MissingDependencyError` — soft-dep gem missing (carries `gem_name`, `feature`).

## Design notes
- `ValidationError#issues` carries the list of `Dcc::Validate::Issue` records so callers can introspect what failed.
- `MissingDependencyError` produces a friendly "Add it to your Gemfile" message so users know exactly what to install.

## Verification
- Unit spec: each error class can be raised with a message and the appropriate accessor returns the supplied payload.
