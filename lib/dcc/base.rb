# frozen_string_literal: true

# `Dcc::Base` hosts version-agnostic XML mapping modules for every DCC element
# type. Each module follows the `self.included(klass)` pattern from mml so the
# version wrapper classes (`Dcc::V2::*`, `Dcc::V3::*`) can mix them in and add
# version-specific extras.
#
# Inside `class_eval` blocks, constants resolve from `Dcc::Base`'s lexical
# scope, so always use fully-qualified names (e.g. `::Dcc::Namespace::Dcc`).
module Dcc
  module Base
    autoload :Text, "dcc/base/text"
    autoload :StringWithLang, "dcc/base/string_with_lang"
    autoload :ByteData, "dcc/base/byte_data"
    autoload :Formula, "dcc/base/formula"
    autoload :Mathml, "dcc/base/mathml"
    autoload :RichContent, "dcc/base/rich_content"
    autoload :XmlBlob, "dcc/base/xml_blob"
    autoload :Comment, "dcc/base/comment"
    autoload :EquipmentClass, "dcc/base/equipment_class"
    autoload :Contact, "dcc/base/contact"
    autoload :ContactNotStrict, "dcc/base/contact_not_strict"
    autoload :Location, "dcc/base/location"
    autoload :HashType, "dcc/base/hash_type"
    autoload :Identifications, "dcc/base/identifications"
    autoload :Identification, "dcc/base/identification"
    autoload :Software, "dcc/base/software"
    autoload :SoftwareList, "dcc/base/software_list"
    autoload :RefTypeDefinition, "dcc/base/ref_type_definition"
    autoload :RefTypeDefinitionList, "dcc/base/ref_type_definition_list"
    autoload :CoreData, "dcc/base/core_data"
    autoload :Item, "dcc/base/item"
    autoload :ItemList, "dcc/base/item_list"
    autoload :CalibrationLaboratory, "dcc/base/calibration_laboratory"
    autoload :RespPerson, "dcc/base/resp_person"
    autoload :RespPersonList, "dcc/base/resp_person_list"
    autoload :Statement, "dcc/base/statement"
    autoload :StatementList, "dcc/base/statement_list"
    autoload :MeasuringEquipment, "dcc/base/measuring_equipment"
    autoload :MeasuringEquipmentList, "dcc/base/measuring_equipment_list"
    autoload :UsedMethod, "dcc/base/used_method"
    autoload :UsedMethodList, "dcc/base/used_method_list"
    autoload :InfluenceCondition, "dcc/base/influence_condition"
    autoload :InfluenceConditionList, "dcc/base/influence_condition_list"
    autoload :Condition, "dcc/base/condition"
    autoload :Result, "dcc/base/result"
    autoload :ResultList, "dcc/base/result_list"
    autoload :Data, "dcc/base/data"
    autoload :Quantity, "dcc/base/quantity"
    autoload :List, "dcc/base/list"
    autoload :MeasurementResult, "dcc/base/measurement_result"
    autoload :MeasurementResultList, "dcc/base/measurement_result_list"
    autoload :MeasurementMetaData, "dcc/base/measurement_meta_data"
    autoload :MeasurementMetaDataList, "dcc/base/measurement_meta_data_list"
    autoload :AdministrativeData, "dcc/base/administrative_data"
    autoload :DigitalCalibrationCertificate, "dcc/base/digital_calibration_certificate"
  end
end
