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
          @plugin_rules = ::Dcc::Plugin.all(:validators).freeze
          @rules = (DEFAULT_RULES + @plugin_rules).freeze
        end

        # Run all rules and return a `Dcc::Validate::Result`.
        #
        # Built-in rules fail fast: a crash there is a bug in this gem. A
        # plugin rule is third-party code, so its failure is contained and
        # reported as an error issue naming the rule class — one broken
        # plugin must not cost the caller every built-in finding.
        def call
          issues = []
          rules.each do |rule_class|
            issues.concat(
              if @plugin_rules.include?(rule_class)
                run_plugin_rule(rule_class)
              else
                rule_class.new.check_on(dcc)
              end,
            )
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

        private

        # Run one plugin-supplied rule with fault isolation. Instantiation
        # and #check_on both run inside the rescue, and a non-Array return
        # (nil included) is reported rather than passed to Array#concat.
        #
        # @param rule_class [Class]
        # @return [Array<Dcc::Validate::Issue>]
        def run_plugin_rule(rule_class)
          result = rule_class.new.check_on(dcc)
          return result if result.is_a?(::Array)

          [plugin_failure_issue(
            rule_class,
            "returned #{result.inspect} instead of an Array of issues",
          )]
        rescue ::StandardError => e
          [plugin_failure_issue(rule_class, "raised #{e.class}: #{e.message}")]
        end

        # @param rule_class [Class]
        # @param detail [String]
        # @return [Dcc::Validate::Issue]
        def plugin_failure_issue(rule_class, detail)
          name = rule_class.name || rule_class.inspect
          ::Dcc::Validate::Issue.build(
            severity: ::Dcc::Validate::Severity::ERROR,
            message: "plugin validator #{name} #{detail}",
            code: "dcc.schematron.plugin_failure",
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
