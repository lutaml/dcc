# 21 — XSLT transform (P2)

**Status:** COMPLETED

## Goal
Apply XSLT stylesheets to DCC XML. Default engine: Nokogiri (XSLT 1.0). Optional `:saxon` engine shells out to Saxon-HE for XSLT 2.0/3.0.

## Files
- `lib/dcc/transform.rb` — autoloads.
- `lib/dcc/transform/xslt.rb` — `Dcc::Transform::Xslt.call(xml, stylesheet, engine: :nokogiri)` returns the transformed String.
- `lib/dcc/transform/result.rb` — result model.

## Design notes
- Nokogiri::XSLT is XSLT 1.0 only — document prominently.
- Saxon bridge: detect `ENV["SAXON_JAR"]` or `which java`, run `java -cp "$SAXON_JAR" net.sf.saxon.Transform -s:- -xsl:stylesheet.xsl`.
- PTB ships XSLT 3.0 stylesheets for some operations; the Saxon bridge is opt-in.

## Dependencies
- 01.

## Verification
- Apply identity XSLT to `valid.xml` → output structurally equivalent.
- Spec covers Nokogiri engine; Saxon engine is opt-in (skip if jar absent).
