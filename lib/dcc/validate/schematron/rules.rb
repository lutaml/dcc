# frozen_string_literal: true

# `Dcc::Validate::Schematron::Rules` hosts the 14 pure-Ruby PTB Schematron
# rule classes. Each rule subclasses `Base` and overrides `#check_on(dcc)`.
#
# The parent module autoloads every rule lazily — no `require_relative`
# is used anywhere in this directory (project rule).
module Dcc
  module Validate
    module Schematron
      module Rules
        autoload :Base, "dcc/validate/schematron/rules/base"
        autoload :UsedMethodsPlacement, "dcc/validate/schematron/rules/used_methods_placement"
        autoload :UsedSoftwarePlacement, "dcc/validate/schematron/rules/used_software_placement"
        autoload :InfluenceConditionsPlacement, "dcc/validate/schematron/rules/influence_conditions_placement"
        autoload :SchemaVersionCheck, "dcc/validate/schematron/rules/schema_version_check"
        autoload :IdRefIdLinking, "dcc/validate/schematron/rules/id_refid_linking"
        autoload :IsoCodeValidation, "dcc/validate/schematron/rules/iso_code_validation"
        autoload :DateRangeCheck, "dcc/validate/schematron/rules/date_range_check"
        autoload :ReleaseFormatCheck, "dcc/validate/schematron/rules/release_format_check"
        autoload :UncertaintyConsistency, "dcc/validate/schematron/rules/uncertainty_consistency"
        autoload :UnitFormatCheck, "dcc/validate/schematron/rules/unit_format_check"
        autoload :NonSiDeclaration, "dcc/validate/schematron/rules/non_si_declaration"
        autoload :LanguageCodeDedup, "dcc/validate/schematron/rules/language_code_dedup"
        autoload :XmlListSpacing, "dcc/validate/schematron/rules/xml_list_spacing"
        autoload :AdministrativeDataCompleteness, "dcc/validate/schematron/rules/administrative_data_completeness"
      end
    end
  end
end
