# 07 — DCC base mapping modules (P1)

**Status:** COMPLETED

## Goal
Create `lib/dcc/base/*.rb` — one shared XML mapping module per DCC element type. Each module uses `self.included(klass)` to inject `attribute` declarations and an `xml do ... end` mapping block. The version wrappers (`Dcc::V2::*`, `Dcc::V3::*`) include these modules and add version-specific extras.

## Files to create
One file per DCC v3.3.0 complexType (≈40 files). Representative subset:

- `lib/dcc/base/digital_calibration_certificate.rb` — root, `schemaVersion` attribute, `administrativeData` + `measurementResults` + optional `comment`/`document`/`ds:Signature`.
- `lib/dcc/base/administrative_data.rb` — `xs:all` container of `dccSoftware`/`coreData`/`items`/`calibrationLaboratory`/`respPersons`/`customer`/`statements`.
- `lib/dcc/base/core_data.rb` — `countryCodeISO3166_1`, `usedLangCodeISO639_1` (collection), `mandatoryLangCodeISO639_1`, `uniqueIdentifier`, `identifications`, dates, `previousReport`.
- `lib/dcc/base/item.rb` + `lib/dcc/base/item_list.rb`.
- `lib/dcc/base/measurement_result.rb` + `lib/dcc/base/result.rb` + `lib/dcc/base/data.rb` (the `xs:choice` over text/formula/byteData/xml/quantity/list).
- `lib/dcc/base/quantity.rb` (wraps D-SI; concrete wiring in Phase 11).
- `lib/dcc/base/list.rb` (recursive list of quantities/lists).
- `lib/dcc/base/statement.rb` (statementMetaDataType with refType/refId in v3).
- `lib/dcc/base/text.rb` (multilingual text container with `xml:lang`).
- `lib/dcc/base/byte_data.rb` (`name`, `description`, `fileName`, `mimeType`, `dataBase64`).
- `lib/dcc/base/formula.rb` (`latex` or `mathml` per v3.4).
- `lib/dcc/base/contact.rb` (strict and not-strict variants).
- `lib/dcc/base/software.rb` (with v3 `type` enum).
- `lib/dcc/base/identifications.rb`.
- `lib/dcc/base/used_methods.rb`, `lib/dcc/base/used_software.rb`.
- `lib/dcc/base/influence_conditions.rb`.
- `lib/dcc/base/measuring_equipment.rb`.
- `lib/dcc/base/resp_person.rb`.
- `lib/dcc/base/calibration_laboratory.rb`.
- `lib/dcc/base/customer.rb`.
- `lib/dcc/base/equipment_class.rb`.
- `lib/dcc/base/location.rb`.
- `lib/dcc/base/hash.rb` (previousReport hash reference).
- Plus v3.4.0-rc.2 modules: `lib/dcc/base/measurand.rb`, `rich_content.rb`, `ref_type_definition.rb`, `relative_uncertainty.rb`, `position_coordinates.rb`, `performance_location.rb`, `report_amended_substituted.rb`, `primitive_quantity.rb`.

Each module follows this template:

```ruby
module Dcc
  module Base
    module AdministrativeData
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :dcc_software, DccSoftware, collection: true
          attribute :core_data, CoreData
          attribute :items, ItemList
          attribute :calibration_laboratory, CalibrationLaboratory
          attribute :resp_persons, RespPersonList
          attribute :customer, Contact
          attribute :statements, StatementList, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "administrativeData"
            ordered
            map_attribute "id", to: :id
            map_element "dccSoftware", to: :dcc_software
            # ...
          end
        end
      end
    end
  end
end
```

## Design notes
- Use `choice` DSL for `dcc:dataType` content model.
- Use `mixed_content` + `map_content` for multilingual `dcc:text` content.
- Use `map_all to: :comment` for the `dcc:comment` xs:any wildcard.
- All attribute references are to `Dcc::Base::*` module names — the version wrapper classes resolve them via the type registry.

## Dependencies
- 02 (Namespace classes), 03 (ContextConfiguration), 04 (Custom types).

## Verification
- Each module included into a test class produces correct `xml do` block.
- Per-module spec covers: round-trip a synthetic XML snippet, assert attribute access.
