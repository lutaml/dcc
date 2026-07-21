# 08 — Dcc::V2 wrappers (P1)

**Status:** PENDING

## Goal
Thin wrapper classes for every DCC element under `Dcc::V2::*`, each including the appropriate `Dcc::Base::*` module and registering in the `:dcc_v2` context.

## Files to create
- `lib/dcc/v2.rb` — module body: `extend Dcc::VersionedParser`, `ROOT_ELEMENT_TAG = "digitalCalibrationCertificate"`, autoload all element classes, eager-register via `Configuration.populate_context!`.
- `lib/dcc/v2/configuration.rb` — `module Dcc::V2::Configuration; extend Dcc::ContextConfiguration; CONTEXT_ID = :dcc_v2; end`.
- `lib/dcc/v2/namespace.rb` — `Dcc::V2::Namespace = Dcc::Namespace::Dcc` with version "2.x" + schemaLocation override.
- `lib/dcc/v2/common_elements.rb` — base class for V2 element wrappers, defines `lutaml_default_register` returning `:dcc_v2`.
- One file per element: `lib/dcc/v2/{digital_calibration_certificate,administrative_data,core_data,item,measurement_result,...}.rb`. Each file:

```ruby
module Dcc::V2
  class AdministrativeData < CommonElements
    include Dcc::Base::AdministrativeData
  end
  Configuration.register_model(AdministrativeData, id: :administrativeData)
end
```

## Design notes
- V2 has no `refId`/`refType` attributes — these are omitted from V2 class declarations.
- V2 imports D-SI v1.x via the older `https://ptb.de/si/v1.x.0/SI_Format.xsd` location.
- V2 supports older `textType`, `byteDataType` (without `dataBase64` rename), `softwareType` (without `type` enum).

## Dependencies
- 07 (DCC base modules).

## Verification
- `Dcc::V2.parse(fixture_xml_v2_3_0)` returns a `Dcc::V2::DigitalCalibrationCertificate`.
- Spec covers every wrapper class: parse + serialize + assert class identity.
