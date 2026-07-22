# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Warn when the schemaVersion is not the latest known release.
        class SchemaVersionCheck < Base
          def severity
            ::Dcc::Validate::Severity::WARNING
          end

          def check_on(dcc)
            return [] unless dcc.respond_to?(:schema_version)

            current = dcc.schema_version.to_s
            latest = ::Dcc::Schema::Version::DCC_LATEST

            current == latest ? [] : [
              issue(
                severity: :warning,
                message: "schemaVersion '#{current}' is not the latest release (#{latest})",
              ),
            ]
          end
        end
      end
    end
  end
end