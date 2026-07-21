# frozen_string_literal: true

module Dcc
  module Validate
    # Severity levels for validation issues. Matches PTB's Schematron roles
    # plus the standard error/warning/info distinction.
    module Severity
      ERROR = :error
      WARNING = :warning
      INFO = :info
      UNKNOWN = :unknown

      ALL = [ERROR, WARNING, INFO, UNKNOWN].freeze

      class << self
        # Coerce a string/symbol to a canonical severity symbol.
        # @return [Symbol]
        def normalize(value)
          return value if ALL.include?(value)
          return UNKNOWN unless value

          sym = value.to_s.downcase.sub(/\A(strict_)?/, "").to_sym
          case sym
          when :err then ERROR
          when :warn then WARNING
          when :information, :informational then INFO
          else
            ALL.include?(sym) ? sym : UNKNOWN
          end
        end

        # @return [Boolean] whether issues at this severity fail validation.
        def failing?(severity)
          severity == ERROR
        end
      end
    end
  end
end
