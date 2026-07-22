# frozen_string_literal: true


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
            return [] unless Dcc::TypeGuards.has_attribute?(dcc, :measurement_results)

            mr_list = safe_attr(dcc.measurement_results, :measurement_result)
            return [] if mr_list.empty?

            present = mr_list.any? do |mr|
              Dcc::TypeGuards.has_attribute?(mr, :used_software) && !mr.used_software.nil?
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
            return [] unless parent && parent.is_a?(::Lutaml::Model::Serializable) && parent.class.attributes.key?(attr)

            Array(parent.public_send(attr))
          end
        end
      end
    end
  end
end