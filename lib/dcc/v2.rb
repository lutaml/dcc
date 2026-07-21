# frozen_string_literal: true

# `Dcc::V2` hosts all DCC v2.x element wrapper classes. They share the same
# `lib/dcc/base/*.rb` mapping modules as V3 but live in their own class
# hierarchy and register in their own type context (`:dcc_v2`), so V2 and V3
# can coexist in one process without symbol clashes.
module Dcc
  module V2
    autoload :Configuration, "dcc/v2/configuration"
    autoload :Namespace, "dcc/v2/namespace"
    autoload :CommonElements, "dcc/v2/common_elements"

    autoload :StringWithLang, "dcc/v2/string_with_lang"
    autoload :Text, "dcc/v2/text"
    autoload :ByteData, "dcc/v2/byte_data"
    autoload :Formula, "dcc/v2/formula"
    autoload :RichContent, "dcc/v2/rich_content"
    autoload :XmlBlob, "dcc/v2/xml_blob"
    autoload :Comment, "dcc/v2/comment"
    autoload :EquipmentClass, "dcc/v2/equipment_class"
    autoload :Location, "dcc/v2/location"
    autoload :Contact, "dcc/v2/contact"
    autoload :ContactNotStrict, "dcc/v2/contact_not_strict"
    autoload :HashType, "dcc/v2/hash_type"
    autoload :Identification, "dcc/v2/identification"
    autoload :Identifications, "dcc/v2/identifications"
    autoload :Software, "dcc/v2/software"
    autoload :SoftwareList, "dcc/v2/software_list"
    autoload :RefTypeDefinition, "dcc/v2/ref_type_definition"
    autoload :RefTypeDefinitionList, "dcc/v2/ref_type_definition_list"
    autoload :CoreData, "dcc/v2/core_data"
    autoload :Item, "dcc/v2/item"
    autoload :ItemList, "dcc/v2/item_list"
    autoload :CalibrationLaboratory, "dcc/v2/calibration_laboratory"
    autoload :RespPerson, "dcc/v2/resp_person"
    autoload :RespPersonList, "dcc/v2/resp_person_list"
    autoload :Statement, "dcc/v2/statement"
    autoload :StatementList, "dcc/v2/statement_list"
    autoload :MeasuringEquipment, "dcc/v2/measuring_equipment"
    autoload :MeasuringEquipmentList, "dcc/v2/measuring_equipment_list"
    autoload :UsedMethod, "dcc/v2/used_method"
    autoload :UsedMethodList, "dcc/v2/used_method_list"
    autoload :Condition, "dcc/v2/condition"
    autoload :InfluenceCondition, "dcc/v2/influence_condition"
    autoload :InfluenceConditionList, "dcc/v2/influence_condition_list"
    autoload :Result, "dcc/v2/result"
    autoload :ResultList, "dcc/v2/result_list"
    autoload :Data, "dcc/v2/data"
    autoload :Quantity, "dcc/v2/quantity"
    autoload :List, "dcc/v2/list"
    autoload :MeasurementMetaData, "dcc/v2/measurement_meta_data"
    autoload :MeasurementMetaDataList, "dcc/v2/measurement_meta_data_list"
    autoload :MeasurementResult, "dcc/v2/measurement_result"
    autoload :MeasurementResultList, "dcc/v2/measurement_result_list"
    autoload :AdministrativeData, "dcc/v2/administrative_data"
    autoload :DigitalCalibrationCertificate, "dcc/v2/digital_calibration_certificate"

    ROOT_ELEMENT_TAG = "digitalCalibrationCertificate"

    extend ::Dcc::VersionedParser

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

    def self.load_all!
      ELEMENT_CLASSES.each { |name| const_get(name) }
      Configuration.populate_context!
      true
    end
  end
end
