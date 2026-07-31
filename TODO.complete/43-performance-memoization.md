# 43 — Performance: memoize schema lookups (P2)

**Status:** PENDING

## Gaps
- `Dcc::Schema.path` (`lib/dcc/schema.rb:19-21`) is a bare `File.join` with
  no cache.
- `detect_version` is not memoized.
- `spec/perf_spec.rb` does not exist; the benchmark was never run.
- Only the pre-existing `Dcc::Validate::Xsd` cache
  (`lib/dcc/validate/xsd.rb:44`) is in place.

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
