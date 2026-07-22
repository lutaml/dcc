# 15 — Pure-Ruby Schematron (P1)

**Status:** COMPLETED

## Goal
Reimplement PTB's 14 Schematron patterns as `Lutaml::Model::Validation::Rule` subclasses operating on the parsed object tree. No Saxon-HE, no JVM.

## Files
- `lib/dcc/validate/schematron.rb` — autoloads + entry point.
- `lib/dcc/validate/schematron/profile.rb` — `Dcc::Validate::Schematron::Profile < Lutaml::Model::Validation::Profile` aggregating all 14 rules.
- `lib/dcc/validate/schematron/rules/` — 14 rule files, one per PTB pattern:
  - `used_methods_placement.rb` (error if no usedMethods anywhere)
  - `used_software_placement.rb` (warning)
  - `influence_conditions_placement.rb` (error)
  - `schema_version_check.rb` (warning if not "3.3.0")
  - `id_refid_linking.rb` (error: dangling refId; warning: unused id)
  - `iso_code_validation.rb` (ISO 3166-1 + ISO 639-1 enums)
  - `date_range_check.rb` (endPerformanceDate >= beginPerformanceDate)
  - `release_format_check.rb` (regex on dcc:release)
  - `uncertainty_consistency.rb` (value count == uncertainty count)
  - `unit_format_check.rb` (units have no spaces; list counts match)
  - `non_si_declaration.rb` (`|unit` requires dcc:nonSIUnit declaration)
  - `language_code_dedup.rb` (no duplicate usedLangCodeISO639_1)
  - `xml_list_spacing.rb` (single-space separator, no leading/trailing)
  - `administrative_data_completeness.rb` (mandatory sections present)

Each rule subclasses `Lutaml::Model::Validation::Rule`:

```ruby
module Dcc::Validate::Schematron::Rules
  class DateRangeCheck < Lutaml::Model::Validation::Rule
    def code = "dcc.date-range"
    def category = :schematron
    def severity = :error

    def applicable?(context)
      context.subject.is_a?(Dcc::V3::DigitalCalibrationCertificate) ||
      context.subject.is_a?(Dcc::V2::DigitalCalibrationCertificate)
    end

    def check(context)
      dcc = context.subject
      core = dcc.administrative_data&.core_data
      return [] unless core&.begin_performance_date && core&.end_performance_date

      if core.end_performance_date < core.begin_performance_date
        [issue(line: nil, message: "endPerformanceDate precedes beginPerformanceDate")]
      else
        []
      end
    end
  end
end
```

## Design notes
- Rules walk the parsed object tree — no XPath over raw XML.
- Each rule emits `Dcc::Validate::Issue` records with line numbers where available.
- Some rules apply to specific versions only (use `applicable?` to gate).

## Dependencies
- 12.

## Verification
- `Dcc::Validate::Schematron.call(dcc).ok?` is true on `valid.xml`, false on `invalid_schematron.xml`.
- Each rule has at least one negative spec with a crafted fixture.
