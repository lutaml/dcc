# 31 — REST API server (P3, optional)

**Status:** PENDING

## Goal
Rack/Sinatra REST API matching PTB's endpoints: `/dccs`, `/dccs/:id/validate/{xsd,schematron}`, `/dccs/:id/convert/json`, `/dccs/:id/extract/{files,formulae}`, `/dccs/:id/signature`, `/dccs/:id/transform/xslt`.

## Files
- `lib/dcc/server.rb` — autoloads.
- `lib/dcc/server/app.rb` — Sinatra app.
- `lib/dcc/server/storage.rb` — pluggable storage (Memory, Disk, Redis).
- Soft-dep on `sinatra`; raise `MissingDependencyError` if not installed.

## Design notes
- Same service objects as the CLI — the server is a thin HTTP wrapper.
- Storage SHA-256-keyed like PTB; TTL configurable.

## Dependencies
- 24.

## Verification
- `rackup` starts the server; `curl localhost:9292/dccs` returns JSON.
