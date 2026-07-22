# 32 — i18n / multilingual navigation helpers (P3)

**Status:** COMPLETED

## Goal
Pick the best language from `dcc:textType`, validate language coverage, and provide fallback rules for multilingual content.

## Files
- `lib/dcc/i18n.rb` — autoloads.
- `lib/dcc/i18n/text_lookup.rb` — `Dcc::I18n::TextLookup.call(text_type, lang: "en", fallback: %i[used mandatory])`.

## Design notes
- Respects `usedLangCodeISO639_1` and `mandatoryLangCodeISO639_1` from coreData.
- Returns the best match or raises if no mandatory coverage.

## Dependencies
- 12.

## Verification
- Spec covers happy path + missing-language fallback + mandatory-coverage failure.
