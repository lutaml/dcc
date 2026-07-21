# TODO.complete — dcc gem work breakdown

This directory holds the actionable work breakdown for the dcc gem. Each
file is one self-contained phase. See the master plan at
`/Users/mulgogi/.claude/plans/investigate-src-ptb-dcclib-src-ptb-dccex-fluffy-pike.md`
for the full architecture and design rationale.

## Priority levels

- **P0** — foundation; blocks all subsequent work. Phases 01-06.
- **P1** — core feature parity with PTB Python dcclib. Phases 07-19.
- **P2** — features that exceed PTB ("the fantastic extras"). Phases 20-30.
- **P3** — optional / nice-to-have. Phases 31-35.

## Status legend

- `COMPLETED` — phase is done and verified.
- `IN PROGRESS` — actively being worked.
- `PENDING` — not yet started.

## Phase index

| # | Pri | Title | Status | Blocked by |
|--|--|--|--|--|
| 01 | P0 | Scaffolding | COMPLETED | — |
| 02 | P0 | Namespace classes | COMPLETED | 01 |
| 03 | P0 | ContextConfiguration + VersionedParser | COMPLETED | 01 |
| 04 | P0 | Custom types | COMPLETED | 02 |
| 05 | P0 | Bundle XSD/Schematron resources + fixtures | COMPLETED | 01 |
| 06 | P0 | Error hierarchy | COMPLETED | 01 |
| 07 | P1 | DCC base mapping modules | COMPLETED | 02, 03, 04 |
| 08 | P1 | Dcc::V2 wrappers | COMPLETED | 07 |
| 09 | P1 | Dcc::V3 wrappers | COMPLETED | 07 |
| 10 | P1 | D-SI model | COMPLETED | 04 |
| 11 | P1 | Wire DCC ↔ D-SI | COMPLETED | 09, 10 |
| 12 | P1 | Root parser API | COMPLETED | 08, 09, 11 |
| 13 | P1 | Round-trip fidelity specs | COMPLETED | 12 |
| 14 | P1 | XSD validation | COMPLETED | 05, 12 |
| 15 | P1 | Pure-Ruby Schematron | COMPLETED | 12 |
| 16 | P1 | Business rule validators | COMPLETED | 12 |
| 17 | P1 | JSON converter | COMPLETED | 12 |
| 18 | P1 | File extraction | COMPLETED | 12 |
| 19 | P1 | Formula extraction | PENDING | 12 |
| 20 | P2 | XMLDSig signature | COMPLETED | 12 |
| 21 | P2 | XSLT transform | COMPLETED | 01 |
| 22 | P2 | Inspection report | COMPLETED | 12 |
| 23 | P2 | Output models with format transforms | COMPLETED | 14-19 |
| 24 | P2 | CLI scaffold | COMPLETED | 14-22 |
| 25 | P2 | YAML/CSV/HTML converters | COMPLETED | 17 |
| 26 | P2 | Builder DSL | COMPLETED | 09, 11 |
| 27 | P2 | DCC diff tool | COMPLETED | 12 |
| 28 | P2 | Version migration | COMPLETED | 08, 09 |
| 29 | P2 | Uncertainty propagation | COMPLETED | 10 |
| 30 | P2 | Quantity pretty-printing | COMPLETED | 10 |
| 31 | P3 | REST API server | PENDING | 24 |
| 32 | P3 | i18n navigation helpers | PENDING | 12 |
| 33 | P3 | Streaming parser | PENDING | 12 |
| 34 | P3 | Plugin system | PENDING | 14-19 |
| 35 | P3 | Documentation | PENDING | all |

## Critical path

01 → 02, 03, 04, 05, 06 (parallel) → 07 → 08, 09, 10 (parallel) → 11 → 12.
After 12 (root parser), feature phases 14-30 parallelize and are now all done.

## Remaining

P1 phase 19 (Formula extraction) and P3 phases 31-35 remain as
follow-up work. Each is documented in its TODO file with concrete next
steps.
