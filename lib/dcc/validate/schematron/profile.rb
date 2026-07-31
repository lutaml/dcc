# frozen_string_literal: true

require "bigdecimal"
require "date"

module Dcc
  module Validate
    module Schematron
      # `Dcc::Validate::Schematron::Profile` aggregates the 14 PTB Schematron
      # rules and runs them against a parsed DCC object tree. Each rule is a
      # `Lutaml::Model::Validation::Rule` subclass that walks the parsed tree.
      #
      # @example
      #   result = Dcc::Validate::Schematron.call(dcc)
      #   result.ok?           # => true
      #   result.issues.size   # => 0
      class Profile
        # The rules shipped with the gem, in execution order.
        DEFAULT_RULES = [
          Rules::UsedMethodsPlacement,
          Rules::UsedSoftwarePlacement,
          Rules::InfluenceConditionsPlacement,
          Rules::SchemaVersionCheck,
          Rules::IdRefIdLinking,
          Rules::IsoCodeValidation,
          Rules::DateRangeCheck,
          Rules::ReleaseFormatCheck,
          Rules::UncertaintyConsistency,
          Rules::UnitFormatCheck,
          Rules::NonSiDeclaration,
          Rules::LanguageCodeDedup,
          Rules::XmlListSpacing,
        ].freeze
        private_constant :DEFAULT_RULES

        attr_reader :dcc, :rules

        # Plugin validators are read here, not at class-definition time, so
        # a plugin loaded after this class still takes effect. Frozen because
        # `attr_reader :rules` hands the array straight to callers.
        def initialize(dcc)
          @dcc = dcc
          @rules = (DEFAULT_RULES + ::Dcc::Plugin.all(:validators)).freeze
        end

        # Run all rules and return a `Dcc::Validate::Result`.
        def call
          issues = []
          rules.each do |rule_class|
            issues.concat(rule_class.new.check_on(dcc))
          end

          ::Dcc::Validate::Result.new(
            issues: issues,
            schema_version: if Dcc::TypeGuards.has_attribute?(dcc,
                                                              :schema_version)
                              dcc.schema_version.to_s
                            end,
            source: "schematron",
          )
        end

        class << self
          # Convenience class method.
          # @param dcc [Lutaml::Model::Serializable]
          # @return [Dcc::Validate::Result]
          def call(dcc)
            new(dcc).call
          end
        end
      end
    end
  end
end
