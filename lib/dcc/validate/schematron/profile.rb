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
        attr_reader :dcc, :rules

        def initialize(dcc)
          @dcc = dcc
          @rules = [
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
          ]
        end

        # Run all rules and return a `Dcc::Validate::Result`.
        def call
          issues = []
          rules.each do |rule_class|
            issues.concat(rule_class.new.check_on(dcc))
          end

          ::Dcc::Validate::Result.new(
            issues: issues,
            schema_version: dcc.respond_to?(:schema_version) ? dcc.schema_version.to_s : nil,
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