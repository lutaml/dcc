# 33 — Streaming parser for large documents (P3)

**Status:** COMPLETED

## Outcome
Built on `Moxml::SAX` rather than the `Nokogiri::XML::Reader` named in the
Goal below. `CONTRIBUTING.adoc` bans Nokogiri outside
`lib/dcc/validate/xsd.rb`, so the reader could not use it. The lazy,
constant-memory streaming this phase asked for is unaffected.

Items and quantities are enumerable; results are not separately streamable.
Reach a result through the item that owns it.

Memory is verified by `spec/support/streaming_memory_probe.rb`, which runs in
a child process and asserts retained heap stays flat as the stream advances,
instead of the 50 MB / 200 MB fixture in the Verification section below. That
bounds growth at any document size rather than at one size.

`spec/dcc/streaming/reader_spec.rb`, removed in phase 38, is replaced by
`spec/dcc/streaming_spec.rb`.

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
