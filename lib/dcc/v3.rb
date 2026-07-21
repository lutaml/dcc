# frozen_string_literal: true

# `Dcc::V3` hosts all DCC v3.x element wrapper classes. They share the same
# `lib/dcc/base/*.rb` mapping modules as V2 but live in their own class
# hierarchy and register in their own type context (`:dcc_v3`), so V2 and V3
# can coexist in one process without symbol clashes.
module Dcc
  module V3
    autoload :Configuration, "dcc/v3/configuration"
    autoload :Namespace, "dcc/v3/namespace"
    autoload :CommonElements, "dcc/v3/common_elements"

    autoload :StringWithLang, "dcc/v3/string_with_lang"
    autoload :Text, "dcc/v3/text"
    autoload :ByteData, "dcc/v3/byte_data"
    autoload :Formula, "dcc/v3/formula"
    autoload :RichContent, "dcc/v3/rich_content"
    autoload :XmlBlob, "dcc/v3/xml_blob"
    autoload :Comment, "dcc/v3/comment"
    autoload :EquipmentClass, "dcc/v3/equipment_class"
    autoload :Location, "dcc/v3/location"
    autoload :Contact, "dcc/v3/contact"
    autoload :ContactNotStrict, "dcc/v3/contact_not_strict"
    autoload :HashType, "dcc/v3/hash_type"
    autoload :Identification, "dcc/v3/identification"
    autoload :Identifications, "dcc/v3/identifications"
    autoload :Software, "dcc/v3/software"
    autoload :SoftwareList, "dcc/v3/software_list"
    autoload :RefTypeDefinition, "dcc/v3/ref_type_definition"
    autoload :RefTypeDefinitionList, "dcc/v3/ref_type_definition_list"
    autoload :CoreData, "dcc/v3/core_data"
    autoload :Item, "dcc/v3/item"
    autoload :ItemList, "dcc/v3/item_list"
    autoload :CalibrationLaboratory, "dcc/v3/calibration_laboratory"
    autoload :RespPerson, "dcc/v3/resp_person"
    autoload :RespPersonList, "dcc/v3/resp_person_list"
    autoload :Statement, "dcc/v3/statement"
    autoload :StatementList, "dcc/v3/statement_list"
    autoload :MeasuringEquipment, "dcc/v3/measuring_equipment"
    autoload :MeasuringEquipmentList, "dcc/v3/measuring_equipment_list"
    autoload :UsedMethod, "dcc/v3/used_method"
    autoload :UsedMethodList, "dcc/v3/used_method_list"
    autoload :Condition, "dcc/v3/condition"
    autoload :InfluenceCondition, "dcc/v3/influence_condition"
    autoload :InfluenceConditionList, "dcc/v3/influence_condition_list"
    autoload :Result, "dcc/v3/result"
    autoload :ResultList, "dcc/v3/result_list"
    autoload :Data, "dcc/v3/data"
    autoload :Quantity, "dcc/v3/quantity"
    autoload :List, "dcc/v3/list"
    autoload :MeasurementMetaData, "dcc/v3/measurement_meta_data"
    autoload :MeasurementMetaDataList, "dcc/v3/measurement_meta_data_list"
    autoload :MeasurementResult, "dcc/v3/measurement_result"
    autoload :MeasurementResultList, "dcc/v3/measurement_result_list"
    autoload :AdministrativeData, "dcc/v3/administrative_data"
    autoload :DigitalCalibrationCertificate, "dcc/v3/digital_calibration_certificate"

    ROOT_ELEMENT_TAG = "digitalCalibrationCertificate"

    extend ::Dcc::VersionedParser

    # Element wrapper classes that must be loaded before
    # `Configuration.populate_context!` can register them. Iterating
    # `constants` triggers each autoload lazily.
    ELEMENT_CLASSES = %i[
      StringWithLang Text ByteData Formula RichContent XmlBlob Comment
      EquipmentClass Location Contact ContactNotStrict HashType
      Identification Identifications Software SoftwareList
      RefTypeDefinition RefTypeDefinitionList
      CoreData Item ItemList CalibrationLaboratory
      RespPerson RespPersonList Statement StatementList
      MeasuringEquipment MeasuringEquipmentList
      UsedMethod UsedMethodList
      Condition InfluenceCondition InfluenceConditionList
      Result ResultList Data Quantity List
      MeasurementMetaData MeasurementMetaDataList
      MeasurementResult MeasurementResultList
      AdministrativeData DigitalCalibrationCertificate
    ].freeze

    # Eagerly load every element wrapper so registrations run.
    def self.load_all!
      ELEMENT_CLASSES.each { |name| const_get(name) }
      Configuration.populate_context!
      true
    end
  end
end
