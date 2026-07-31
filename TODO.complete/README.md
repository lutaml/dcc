# TODO.complete — dcc gem work breakdown

This directory holds the actionable work breakdown for the dcc gem. Each
file is one self-contained phase. The original master plan is not tracked
in this repository.

Statuses describe work merged into the default branch. See the
repository's open pull requests for work in progress.

Statuses were last audited against commit `9fbbb4a`. They are a snapshot —
re-verify against the current tree before relying on them.

## Priority levels

- **P0** — foundation; blocks all subsequent work.
- **P1** — core feature parity with PTB Python dcclib.
- **P2** — features that exceed PTB ("the fantastic extras").
- **P3** — optional / nice-to-have.

Each phase's own priority is in its file header. Phases 36-45 are
follow-up work added after the original 01-35 breakdown and mix all four
levels.

## Status legend

- `COMPLETED` — phase is done and verified.
- `PARTIAL` — the core goal works, but a named deliverable is missing,
  is not wired into anything, or behaves differently than this file
  describes. Each such file has a `## Gaps` section with the specifics.
- `IN PROGRESS` — actively being worked.
- `PENDING` — not yet started.

## Phase index

| # | Pri | Title | Status | Blocked by |
|--|--|--|--|--|
| 01 | P0 | Scaffolding | COMPLETED | — |
| 02 | P0 | Namespace classes | COMPLETED | 01 |
| 03 | P0 | ContextConfiguration + VersionedParser | COMPLETED | 01 |
| 04 | P0 | Custom types | PARTIAL | 02 |
| 05 | P0 | Bundle XSD/Schematron resources + fixtures | COMPLETED | 01 |
| 06 | P0 | Error hierarchy | COMPLETED | 01 |
| 07 | P1 | DCC base mapping modules | PARTIAL | 02, 03, 04 |
| 08 | P1 | Dcc::V2 wrappers | COMPLETED | 07 |
| 09 | P1 | Dcc::V3 wrappers | PARTIAL | 07 |
| 10 | P1 | D-SI model | PARTIAL | 04 |
| 11 | P1 | Wire DCC ↔ D-SI | COMPLETED | 09, 10 |
| 12 | P1 | Root parser API | COMPLETED | 08, 09, 11 |
| 13 | P1 | Round-trip fidelity specs | PARTIAL | 12 |
| 14 | P1 | XSD validation | COMPLETED | 05, 12 |
| 15 | P1 | Pure-Ruby Schematron | PARTIAL | 12 |
| 16 | P1 | Business rule validators | PARTIAL | 12 |
| 17 | P1 | JSON converter | PARTIAL | 12 |
| 18 | P1 | File extraction | PARTIAL | 12 |
| 19 | P1 | Formula extraction | PENDING | 12 |
| 20 | P2 | XMLDSig signature | COMPLETED | 12 |
| 21 | P2 | XSLT transform | COMPLETED | 01 |
| 22 | P2 | Inspection report | PARTIAL | 12 |
| 23 | P2 | Output models with format transforms | PARTIAL | 14-19 |
| 24 | P2 | CLI scaffold | PARTIAL | 14-22 |
| 25 | P2 | YAML/CSV/HTML converters | PARTIAL | 17 |
| 26 | P2 | Builder DSL | PARTIAL | 09, 11 |
| 27 | P2 | DCC diff tool | COMPLETED | 12 |
| 28 | P2 | Version migration | PARTIAL | 08, 09 |
| 29 | P2 | Uncertainty propagation | PARTIAL | 10 |
| 30 | P2 | Quantity pretty-printing | PARTIAL | 10 |
| 31 | P3 | REST API server | PARTIAL | 24 |
| 32 | P3 | i18n navigation helpers | PARTIAL | 12 |
| 33 | P3 | Streaming parser | PENDING | 12 |
| 34 | P3 | Plugin system | PARTIAL | 14-19 |
| 35 | P3 | Documentation | PARTIAL | all |
| 36 | P0 | Remove require_relative in Schematron rules | COMPLETED | — |
| 37 | P1 | Implement stub Schematron rules | PARTIAL | 15 |
| 38 | P1 | Convert pending specs to passing specs | COMPLETED | — |
| 39 | P1 | Complete Dcc::Si::V1 wrappers | COMPLETED | 10 |
| 40 | P2 | Wire Dcc::V2::Quantity to D-SI v1 | COMPLETED | 10, 39 |
| 41 | P2 | YARD documentation | PARTIAL | — |
| 42 | P2 | CHANGELOG + CONTRIBUTING | PARTIAL | — |
| 43 | P2 | Performance: memoize schema lookups | PENDING | — |
| 44 | P3 | Final code-quality pass + rubocop | COMPLETED | — |
| 45 | P0 | Eliminate respond_to? calls from lib/ | PARTIAL | — |

Totals: 17 COMPLETED, 25 PARTIAL, 3 PENDING.

## Critical path

01 → 02, 03, 04, 05, 06 (parallel) → 07 → 08, 09, 10 (parallel) → 11 → 12.
After 12 (root parser), the feature phases 13-35 parallelize. Most of
them landed, but several shipped without a named deliverable — see the
PARTIAL rows above.

## Remaining

**PENDING — not started.**

- **19** Formula extraction. None of the five files exist, and
  `lib/dcc/extract.rb:7` autoloads `:Formula`, so referencing
  `Dcc::Extract::Formula` raises `LoadError`.
- **33** Streaming parser. Neither file exists; nothing in `lib/` uses
  `Nokogiri::XML::Reader`.
- **43** Performance memoization. Only the pre-existing
  `Dcc::Validate::Xsd` cache is in place; `Schema.path` and
  `detect_version` are uncached and `spec/perf_spec.rb` does not exist.

**PARTIAL — usable, with a documented gap.** Each file's `## Gaps`
section has the detail.

- Model coverage: **07** (six v3.4.0-rc.2 modules), **09** (`:dcc_v3_4`
  context never registered), **10** (D-SI multivariate uncertainty),
  **04** (`Base64Binary` returns text, `SchemaVersion` lacks
  minor/patch).
- Validation: **15** and **37** (`AdministrativeDataCompleteness` is
  written but absent from the profile, so it never runs), **16** (two of
  the four business rules).
- Output and conversion: **17** (no `style:` selector), **22** (missing
  report sections; `has_signature` reads the wrong element), **23** (no
  shared `Dcc::Output` concern), **25** (HTML report has no collapsible
  tree or language selector), **30** (documented example does not match
  the output).
- Features: **18** (only two of four rings detected), **24** (three CLI
  command groups missing), **26** (builder cannot express measured
  values), **28** (migration is a re-parse shim), **29** (no complex or
  matrix arithmetic), **31** (none of the PTB endpoints), **32** (missing
  language coverage never raises), **34** (nothing consumes the plugin
  registry).
- Housekeeping: **13** (round-trip specs assert a substring, not
  canonical equivalence), **35** and **41** (`yard` is not in the
  Gemfile), **42** (CHANGELOG overstates 41 and 43), **45** (six
  `respond_to?` calls remain).
