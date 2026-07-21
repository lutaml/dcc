# 20 — XMLDSig signature (P2)

**Status:** PENDING

## Goal
Sign a DCC with XMLDSig (enveloped RSA-SHA-256) and verify signed DCCs against a CA certificate.

## Files
- `lib/dcc/signature.rb` — autoloads.
- `lib/dcc/signature/signer.rb` — `Dcc::Signature::Signer.call(dcc_or_xml, cert:, key:)` returns a signed XML String.
- `lib/dcc/signature/verifier.rb` — `Dcc::Signature::Verifier.call(xml, ca_cert:)` returns `Dcc::Signature::Result` with `valid?`, `certificate`, `signed_xml`.
- `lib/dcc/signature/result.rb` — result model with `to_s`, `to_json`, `to_yaml`.

## Design notes
- Soft-dependency on `xmldsig` gem. If not installed, raise `Dcc::Error::MissingDependencyError` with friendly message.
- Fallback: shell out to `xmlsec1` CLI if `xmldsig` lacks an algorithm.
- Extract the signed subtree via `Verifier` so callers know what's actually trustworthy (per PTB warning).

## Dependencies
- 12.

## Verification
- Sign `valid.xml` with PTB test certs; verify with the matching CA cert; result `valid?` is true.
- Tamper with the signed XML and re-verify; `valid?` is false.
