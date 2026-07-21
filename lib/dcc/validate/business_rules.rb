# frozen_string_literal: true

module Dcc
  module Validate
    # Ruby-side semantic checks that go beyond Schematron. Cross-section
    # consistency, signer coverage, language completeness. Open for
    # extension via the Registry class.
    module BusinessRules
      # Output of running business rules. Same shape as Validate::Result.
      class Result < ::Dcc::Validate::Result
      end

      # Registry of all registered business rules. Plugins call
      # `Dcc::Validate::BusinessRules::Registry.add(rule_class)` to add
      # new rules without modifying this file (OCP).
      class Registry
        @rules = []

        class << self
          attr_reader :rules

          # @param rule_class [Class] subclass of Rule.
          def add(rule_class)
            @rules << rule_class
            rule_class
          end

          # @return [Array<Class>]
          def all
            @rules
          end

          def reset!
            @rules.clear
          end
        end
      end

      # Base class for business rules.
      class Rule
        def severity
          ::Dcc::Validate::Severity::ERROR
        end

        def code
          "dcc.business_rule.#{self.class.name.split('::').last.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase}"
        end

        # @param _dcc [Lutaml::Model::Serializable]
        # @return [Array<Dcc::Validate::Issue>]
        def check_on(_dcc)
          []
        end

        protected

        def issue(severity:, message:, path: nil)
          ::Dcc::Validate::Issue.build(
            severity: severity,
            message: message,
            code: code,
            path: path,
            source: "business_rule",
          )
        end
      end

      # Require exactly one respPerson with mainSigner = true.
      class MainSignerSingle < Rule
        def check_on(dcc)
          return [] unless dcc.respond_to?(:administrative_data)

          admin = dcc.administrative_data
          return [] unless admin&.respond_to?(:resp_persons) && admin.resp_persons

          resp_persons = Array(admin.resp_persons.resp_person)
          main_signers = resp_persons.select { |p| p.respond_to?(:main_signer) && p.main_signer }
          return [] if main_signers.size == 1

          [
            issue(
              severity: :error,
              message: "Expected exactly one mainSigner respPerson, found #{main_signers.size}",
            ),
          ]
        end
      end

      # Require non-empty uniqueIdentifier.
      class UniqueIdentifierPresent < Rule
        def check_on(dcc)
          return [] unless dcc.respond_to?(:administrative_data)

          core = dcc.administrative_data&.core_data
          return [issue(severity: :error, message: "coreData is missing")] unless core

          id = core.unique_identifier
          return [] if id && !id.to_s.empty?

          [issue(severity: :error, message: "uniqueIdentifier is missing or empty")]
        end
      end

      Registry.add(MainSignerSingle)
      Registry.add(UniqueIdentifierPresent)

      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Validate::BusinessRules::Result]
        def call(dcc)
          issues = Registry.all.flat_map { |rule_class| rule_class.new.check_on(dcc) }
          Result.new(
            issues: issues,
            schema_version: dcc.respond_to?(:schema_version) ? dcc.schema_version.to_s : nil,
            source: "business_rule",
          )
        end
      end
    end
  end
end