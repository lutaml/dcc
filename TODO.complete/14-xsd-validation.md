# 14 — XSD validation (P1)

**Status:** PENDING

## Goal
`Dcc::Validate::Xsd.call(xml, version:)` validates against any of the 12 bundled DCC XSDs. Auto-detect version when `version: :auto` or nil.

## Files
- `lib/dcc/validate.rb` — autoloads.
- `lib/dcc/validate/result.rb` — `Dcc::Validate::Result` (model with `ok?`, `issues`, `to_s/to_json/to_yaml`), `Dcc::Validate::Issue` (severity, line, column, message, path), `Dcc::Validate::Severity` enum.
- `lib/dcc/validate/error.rb` — `Dcc::Error::SchemaError` already exists; add helpers here.
- `lib/dcc/validate/xsd.rb` — service class:
  ```ruby
  def self.call(xml, version: :auto)
    v = Dcc::Schema::Version.resolve_dcc(version, xml: xml)
    schema_path = Dcc::Schema.path("dcc/v#{v}/dcc.xsd")
    errors = Lutaml::Xml::XsdValidator.validate(xml, [schema_path])
    Result.new(issues: errors.map { |e| Issue.from_lutaml(e) })
  end
  ```

## Design notes
- Do NOT use `validate_xml_with` macro — it resolves paths at class-load time.
- Use `Lutaml::Xml::XsdValidator` directly so we can pick the version at runtime.
- Nokogiri::XML::Schema is XSD 1.0 only. PTB XSDs are 1.0, so this is fine.
- Bundle the XSDs into the lookup chain so `<xs:import>` of D-SI resolves to bundled copies.

## Dependencies
- 05, 12.

## Verification
- `Dcc::Validate::Xsd.call(File.read("spec/fixtures/ptb/valid.xml")).ok?` → true.
- `Dcc::Validate::Xsd.call(File.read("spec/fixtures/ptb/invalid_schema.xml")).ok?` → false; `.issues.first.message` non-empty.
