# 18 — File extraction (P1)

**Status:** COMPLETED

## Goal
Walk a parsed DCC and enumerate every embedded file (`dcc:byteDataType` element) with its ring (administrativeData / measurementResults / comment / document).

## Files
- `lib/dcc/extract.rb` — autoloads.
- `lib/dcc/extract/ring.rb` — `Dcc::Extract::Ring` enum (PTB's "Ring" concept).
- `lib/dcc/extract/file.rb` — `Dcc::Extract::File` model (name, file_name, mime_type, data binary String, ring).
- `Dcc::Extract::File.each(dcc) { |f| ... }` iterates all.
- `Dcc::Extract::File.at(dcc, index)` returns the Nth.
- `Dcc::Extract::File.in_ring(dcc, ring:)` filters by ring.

## Design notes
- Base64 decode via `Dcc::Type::Base64Binary` (already implemented in Phase 04).
- Ring detection: walk parent chain to determine which top-level section contains the file.

## Dependencies
- 12.

## Verification
- `Dcc::Extract::File.each(dcc).to_a.last.mime_type` matches the value in PTB's `extract files` output on the same input.
- Decoding `VGVzdAo=` yields `"Test\n"`.
