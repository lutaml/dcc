# 33 — Streaming parser for large documents (P3)

**Status:** PENDING

## Gaps
- Neither `lib/dcc/streaming.rb` nor `lib/dcc/streaming/reader.rb` exists.
- Nothing in `lib/` uses `Nokogiri::XML::Reader`.
- `spec/dcc/streaming/reader_spec.rb` was removed — see phase 38.

## Goal
Lazy enumeration of items / results / quantities for multi-MB DCC documents using Nokogiri::XML::Reader.

## Files
- `lib/dcc/streaming.rb` — autoloads.
- `lib/dcc/streaming/reader.rb` — `Dcc::Streaming.each_item(io) { |item| ... }`, `.each_quantity(io) { |q| ... }`.

## Design notes
- Stream-parses the document, emits typed objects for matched subtrees.
- Useful for batch processing pipelines that don't need the full tree in memory.

## Dependencies
- 12.

## Verification
- Stream a synthetic 50MB DCC fixture, assert memory stays under 200MB.
