# 36 — Remove require_relative violations in Schematron rules (P0)

**Status:** IN PROGRESS

## Goal
The Schematron rule files (`lib/dcc/validate/schematron/rules/*.rb`) and
`lib/dcc/validate/schematron/rules.rb` use 30 `require_relative` calls
in violation of the project rule: "NEVER use `require_relative` for
internal library code. Use Ruby `autoload` instead."

## Files to modify
- `lib/dcc/validate/schematron/rules.rb` — convert eager `require_relative`
  to autoloads under `Dcc::Validate::Schematron::Rules`
- `lib/dcc/validate/schematron/rules/*.rb` (16 files) — remove
  `require_relative "base"` and use the autoloaded `Base` constant

## Design notes
The base `Dcc::Validate::Schematron::Rule` is autoloaded from
`lib/dcc/validate/schematron.rb`. Rule files inherit from
`Dcc::Validate::Schematron::Rules::Base` which is autoloaded from the
parent `lib/dcc/validate/schematron/rules.rb` aggregator.

## Verification
- `grep -rln require_relative lib/` returns nothing
- `bundle exec rspec` still passes
- Schematron rules load on first use (lazy)
