# 43 — Performance: memoize schema lookups (P2)

**Status:** COMPLETED

## Goal
`Dcc::Validate::Xsd` already memoizes the loaded schema, but other
hot paths could benefit from caching.

## Files
- `lib/dcc/validate/xsd.rb` — already cached
- `lib/dcc/schema.rb` — memoize `Dcc::Schema.path` resolution
- `lib/dcc/detect_version` — memoize per-string if hot
- `Dcc::Si::V2::Real` etc. — ensure no per-instantiation overhead

## Verification
- Benchmark parse of `valid.xml` before/after — should be ≥10% faster
- Add a `spec/perf_spec.rb` with a sanity benchmark
