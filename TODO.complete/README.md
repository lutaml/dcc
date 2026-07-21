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

Each TODO has a `**Status:**` line near the top:

- `COMPLETED` — phase is done and verified.
- `IN PROGRESS` — actively being worked.
- `PENDING` — not yet started.
- `BLOCKED` — waiting on a dependency.

## Phase index

| # | Pri | Title | Status | Blocked by |
|--|--|--|--|--|
| 01 | P0 | Scaffolding | COMPLETED | — |
| 02 | P0 | Namespace classes | COMPLETED | 01 |
| 03 | P0 | ContextConfiguration + VersionedParser | COMPLETED | 01 |
| 04 | P0 | Custom types | COMPLETED | 02 |
| 05 | P0 | Bundle XSD/Schematron resources + fixtures | COMPLETED | 01 |
| 06 | P0 | Error hierarchy | COMPLETED | 01 |
| 07 | P1 | DCC base mapping modules | PENDING | 02, 03, 04 |
| 08 | P1 | Dcc::V2 wrappers | PENDING | 07 |
| 09 | P1 | Dcc::V3 wrappers | PENDING | 07 |
| 10 | P1 | D-SI model | PENDING | 04 |
| 11 | P1 | Wire DCC ↔ D-SI | PENDING | 09, 10 |
| 12 | P1 | Root parser API | PENDING | 08, 09, 11 |
| 13 | P1 | Round-trip fidelity specs | PENDING | 12 |
| 14 | P1 | XSD validation | PENDING | 05, 12 |
| 15 | P1 | Pure-Ruby Schematron | PENDING | 12 |
| 16 | P1 | Business rule validators | PENDING | 12 |
| 17 | P1 | JSON converter | PENDING | 12 |
| 18 | P1 | File extraction | PENDING | 12 |
| 19 | P1 | Formula extraction | PENDING | 12 |
| 20 | P2 | XMLDSig signature | PENDING | 12 |
| 21 | P2 | XSLT transform | PENDING | 01 |
| 22 | P2 | Inspection report | PENDING | 12 |
| 23 | P2 | Output models with format transforms | PENDING | 14-19 |
| 24 | P2 | CLI scaffold | PENDING | 14-22 |
| 25 | P2 | YAML/CSV/HTML converters | PENDING | 17 |
| 26 | P2 | Builder DSL | PENDING | 09, 11 |
| 27 | P2 | DCC diff tool | PENDING | 12 |
| 28 | P2 | Version migration | PENDING | 08, 09 |
| 29 | P2 | Uncertainty propagation | PENDING | 10 |
| 30 | P2 | Quantity pretty-printing | PENDING | 10 |
| 31 | P3 | REST API server | PENDING | 24 |
| 32 | P3 | i18n navigation helpers | PENDING | 12 |
| 33 | P3 | Streaming parser | PENDING | 12 |
| 34 | P3 | Plugin system | PENDING | 14-19 |
| 35 | P3 | Documentation | PENDING | all |

## Critical path

01 → 02, 03, 04, 05, 06 (parallel) → 07 → 08, 09, 10 (parallel) → 11 → 12 → 13.
After 13 (round-trip works), feature phases 14-19 parallelize; CLI (24)
waits for the services it shells.
