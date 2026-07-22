# 39 — Complete Dcc::Si::V1 wrappers (P1)

**Status:** PENDING

## Goal
`Dcc::Si::V1` currently has only the configuration and common_elements
files — no actual V1 element wrappers. For symmetry with V2 and to
support parsing legacy D-SI v1.x documents, add V1 wrappers that mirror
the V2 structure but register in `:dsi_v1`.

## Files
- `lib/dcc/si/v1.rb` — expand autoload list to include all V1 element classes
- `lib/dcc/si/v1/{real,complex,constant,real_list_xml_list,complex_list_xml_list,hybrid,si_list,standard_mu,expanded_mu,coverage_interval_mu,expanded_unc_xml_list,measurement_uncertainty_univariate}.rb`

## Design notes
V1 has a deprecated `expandedUnc` type (superseded by `expandedMU` in
v2). Both should be supported.

## Verification
- D-SI v1 example fixtures (Bronze tier) parse without errors
