# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Validate
    module Schematron
      # Base class for Schematron rules. Subclasses implement `#check_on(dcc)`
      # returning an array of `Dcc::Validate::Issue` records.
      class Rule
        # @return [Symbol] severity for issues this rule produces.
        def severity
          ::Dcc::Validate::Severity::ERROR
        end

        # @return [String] rule code used in `Issue#code`.
        def code
          "dcc.schematron.#{self.class.name.split('::').last.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase}"
        end

        # @param dcc [Lutaml::Model::Serializable]
        # @return [Array<Dcc::Validate::Issue>]
        def check_on(dcc)
          issues = []
          walk(dcc, issues)
          issues
        end

        protected

        def walk(_node, _issues)
          # Override in subclasses to traverse the model tree.
        end

        def issue(severity:, message:, line: nil, column: nil, path: nil, source: "schematron")
          ::Dcc::Validate::Issue.build(
            severity: severity,
            message: message,
            code: code,
            line: line,
            column: column,
            path: path,
            source: source,
          )
        end
      end
    end
  end
end