# frozen_string_literal: true

# Schematron rule auto-loader. Add new rules here to register them in the
# active profile.
require_relative "rules/base"
require_relative "rules/used_methods_placement"
require_relative "rules/used_software_placement"
require_relative "rules/influence_conditions_placement"
require_relative "rules/schema_version_check"
require_relative "rules/id_refid_linking"
require_relative "rules/iso_code_validation"
require_relative "rules/date_range_check"
require_relative "rules/release_format_check"
require_relative "rules/uncertainty_consistency"
require_relative "rules/unit_format_check"
require_relative "rules/non_si_declaration"
require_relative "rules/language_code_dedup"
require_relative "rules/xml_list_spacing"
require_relative "rules/administrative_data_completeness"

module Dcc
  module Validate
    module Schematron
      module Rules
      end
    end
  end
end