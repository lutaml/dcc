# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Validate
    # Result of running one or more validators. Tracks the list of issues
    # and the schema version (when relevant). Renderable as text, JSON, or
    # YAML via `to_s` / `to_json` / `to_yaml`.
    class Result < Lutaml::Model::Serializable
      attribute :issues, ::Dcc::Validate::Issue, collection: true
      attribute :schema_version, :string
      attribute :source, :string

      # @param issues [Array<Dcc::Validate::Issue>] validation issues found.
      # @param schema_version [String, nil] DCC schema version validated against.
      # @param source [String, nil] validator name (xsd, schematron, business_rules, all).
      def initialize(issues: [], schema_version: nil, source: nil)
        super()
        self.issues = issues
        self.schema_version = schema_version
        self.source = source
      end

      # @return [Boolean] true when there are no failing (error) issues.
      def ok?
        issues.none?(&:failing?)
      end

      # @return [Array<Dcc::Validate::Issue>] only the errors.
      def errors
        issues.select(&:failing?)
      end

      # @return [Array<Dcc::Validate::Issue>] only the warnings.
      def warnings
        issues.select { |i| i.severity == ::Dcc::Validate::Severity::WARNING }
      end

      # @return [Array<Dcc::Validate::Issue>] only informational issues.
      def infos
        issues.select { |i| i.severity == ::Dcc::Validate::Severity::INFO }
      end

      # Merge another Result into this one (mutating). Returns self.
      # @param other [Dcc::Validate::Result]
      # @return [Dcc::Validate::Result]
      def merge!(other)
        self.issues = issues + other.issues
        self
      end

      # Non-mutating merge.
      # @return [Dcc::Validate::Result]
      def merge(other)
        dup.merge!(other)
      end

      def to_s
        if ok?
          "OK: no errors found#{schema_version ? " (schemaVersion #{schema_version})" : ''}"
        else
          header = "#{errors.size} error(s), #{warnings.size} warning(s)"
          header += " (schemaVersion #{schema_version})" if schema_version
          body = errors.map(&:to_s).unshift(header).join("\n")
          body
        end
      end

      def to_json(*_args)
        require "json"
        payload = {
          ok: ok?,
          source: source,
          schema_version: schema_version,
          error_count: errors.size,
          warning_count: warnings.size,
          info_count: infos.size,
          issues: issues.map do |i|
            {
              severity: i.severity.to_s,
              code: i.code,
              message: i.message,
              line: i.line,
              column: i.column,
              path: i.path,
              source: i.source,
            }
          end,
        }
        ::JSON.pretty_generate(payload)
      end

      def to_yaml(*_args)
        require "yaml"
        {
          ok: ok?,
          source: source,
          schema_version: schema_version,
          issues: issues.map { |i| [i.severity.to_s, i.message, i.line, i.path] },
        }.to_yaml
      end
    end
  end
end
