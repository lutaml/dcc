# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Validate
    # A single validation issue (XSD error, Schematron failed assert, or
    # business-rule violation). Carries enough metadata for both human and
    # machine reporting.
    class Issue < Lutaml::Model::Serializable
      attribute :severity, :symbol
      attribute :code, :string
      attribute :message, :string
      attribute :line, :integer
      attribute :column, :integer
      attribute :path, :string
      attribute :source, :string

      # Convenience constructor used by validators.
      # @param severity [Symbol, String] see `Dcc::Validate::Severity.normalize`.
      # @param message [String] human-readable description.
      # @param code [String, nil] validator-specific code (e.g. "dcc.date-range").
      # @param line [Integer, nil] XML line number if known.
      # @param column [Integer, nil] XML column number if known.
      # @param path [String, nil] XPath / element path if known.
      # @param source [String, nil] validator name (e.g. "xsd", "schematron").
      def self.build(severity:, message:, code: nil, line: nil, column: nil, path: nil, source: nil)
        new(
          severity: ::Dcc::Validate::Severity.normalize(severity),
          message: message,
          code: code,
          line: line,
          column: column,
          path: path,
          source: source,
        )
      end

      # @return [Boolean] whether this issue fails validation (severity == error).
      def failing?
        severity == ::Dcc::Validate::Severity::ERROR
      end

      def to_s
        loc = []
        loc << "line #{line}" if line
        loc << "col #{column}" if column
        loc << path if path
        loc_str = loc.empty? ? "" : " [#{loc.join(' ')}]"
        code_str = code ? "(#{code}) " : ""
        src_str = source ? "#{source}: " : ""
        "#{src_str}#{severity.upcase} #{code_str}#{message}#{loc_str}"
      end
    end
  end
end
