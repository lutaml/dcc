# 41 — Add YARD documentation throughout (P2)

**Status:** PENDING

## Goal
Add YARD-style `# @!method` and `# @param`/`# @return` annotations to
public API surfaces so `yard doc` produces clean HTML documentation.

## Files
- `lib/dcc.rb` — `Dcc.parse`, `Dcc.build`, `Dcc.migrate`, `Dcc.load_all!`
- `lib/dcc/validate/*.rb` — `Xsd`, `Schematron`, `BusinessRules`
- `lib/dcc/convert/*.rb` — `Json`, `Yaml`, `Csv`, `Html`
- `lib/dcc/extract/*.rb` — `File`, `Formula`
- `lib/dcc/builder.rb`, `lib/dcc/diff.rb`, `lib/dcc/inspect/*.rb`
- `lib/dcc/signature/*.rb`, `lib/dcc/transform/*.rb`
- `lib/dcc/quantity_math.rb`, `lib/dcc/quantity_format.rb`

## Verification
- `bundle exec yard doc lib` runs cleanly
- `yard server` serves complete docs at localhost:8808
