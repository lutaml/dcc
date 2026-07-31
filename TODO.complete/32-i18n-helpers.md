# 32 — i18n / multilingual navigation helpers (P3)

**Status:** PARTIAL

## Gaps
- `TextLookup.call` never raises. Missing mandatory-language coverage falls
  through to the first content element regardless of language, which is the
  failure this helper was meant to catch.
- The signature is `call(text_obj, dcc:, lang:)`; there is no `fallback:`
  parameter.

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
- Spec covers the happy path: a requested language, `lang: nil` falling back to the
  declared ones, and nil input.
- (Not covered: `spec/dcc/i18n/text_lookup_spec.rb` has three examples and reaches
  neither missing-language fallback nor any mandatory-coverage failure.)
