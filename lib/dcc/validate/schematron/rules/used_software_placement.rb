# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # `dcc:usedSoftware` is recommended but only generates a warning.
        class UsedSoftwarePlacement < Base
          def severity
            ::Dcc::Validate::Severity::WARNING
          end

          def check_on(dcc)
            return [] unless dcc.respond_to?(:measurement_results)

            mr_list = safe_attr(dcc.measurement_results, :measurement_result)
            return [] if mr_list.empty?

            present = mr_list.any? do |mr|
              mr.respond_to?(:used_software) && !mr.used_software.nil?
            end

            present ? [] : [
              issue(
                severity: :warning,
                message: "dcc:usedSoftware is missing on every measurementResult",
              ),
            ]
          end

          private

          def safe_attr(parent, attr)
            return [] unless parent&.respond_to?(attr)

            Array(parent.public_send(attr))
          end
        end
      end
    end
  end
end