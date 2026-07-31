# 10 — D-SI model (P1)

**Status:** PARTIAL

## Gaps
- `lib/dcc/si/base/` ships 12 modules, not the ~30 listed below.
- D-SI multivariate uncertainty is unmodelled: covariance matrix,
  covariance, column, ellipsoidal region and rectangular region appear
  nowhere in `lib/`.

## Goal
Build `Dcc::Si::V1::*` and `Dcc::Si::V2::*` covering all D-SI quantity types, uncertainty types, and supporting types (column, covariance, region). Same registry pattern as DCC.

## Files to create
- `lib/dcc/si.rb` — `Dcc::Si` top-level: `parse(input, version: 2)`, `SUPPORTED_VERSIONS = [1, 2]`, `Dcc::Si::UNSPECIFIED_CONTEXT`.
- D-SI reuses `Dcc::VersionedParser`; no separate `si/versioned_parser.rb` was needed.
- D-SI reuses `Dcc::ContextConfiguration` directly; no separate file was needed.
- `lib/dcc/si/namespace.rb` — `Dcc::Si::Namespace = Dcc::Namespace::Si`.
- `lib/dcc/si/common_elements.rb` — shared base for D-SI elements.
- `lib/dcc/si/base/` — one module per D-SI complexType (≈30 files):
  - `quantity.rb` (abstract head)
  - `real.rb`, `complex.rb`, `constant.rb`
  - `real_list.rb`, `complex_list.rb`, `real_list_xml_list.rb`, `complex_list_xml_list.rb`
  - `hybrid.rb`, `si_list.rb` (recursive; drafted as `list.rb`)
  - `standard_mu.rb`, `expanded_mu.rb`, `coverage_interval_mu.rb`
  - `ellipsoidal_region.rb`, `rectangular_region.rb`
  - `covariance_matrix.rb`, `covariance.rb`, `column.rb`
  - `unit.rb`, `quantity_type.rb`, `label.rb`
  - Plus deprecated types (`expanded_unc.rb`, `coverage_interval.rb`) kept for legacy docs.
- `lib/dcc/si/v1.rb`, `lib/dcc/si/v1/configuration.rb` (CONTEXT_ID=:dsi_v1), `lib/dcc/si/v1/common_elements.rb`, and wrapper per element.
- `lib/dcc/si/v2.rb`, `lib/dcc/si/v2/configuration.rb` (CONTEXT_ID=:dsi_v2), `lib/dcc/si/v2/common_elements.rb`, and wrappers.

## Design notes
- Substitution group (`si:quantityType` head) modeled via multiple optional collection attributes (Option B from plan) — most reliable in current lutaml-model.
- `XMLList` types use `Dcc::Type::DecimalXmlList` for value lists.
- D-SI v1 has deprecated `expandedUnc`/`coverageInterval`; v2 uses `expandedMU`/`coverageIntervalMU`. Both modules exist so old fixtures round-trip.
- D-SI v2 imports QUDT for `quantityTypeQUDT`.

## Dependencies
- 04 (Custom types).

## Verification
- Parse each PTB D-SI example (BRONZE → PLATINUM) and round-trip canonically.
- Per-type unit specs cover parse + serialize.
