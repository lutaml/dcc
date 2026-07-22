# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates `dcc:release` format: `^[a-zA-Z]{1}(\s)?([0-9]{1,3}\.){0,3}([0-9]{1,3})$`
        class ReleaseFormatCheck < Base
          PATTERN = /\A[a-zA-Z]{1} ?([0-9]{1,3}\.){0,3}[0-9]{1,3}\z/

          def check_on(dcc)
            issues = []
            return issues unless Dcc::TypeGuards.has_attribute?(dcc, :administrative_data)

            software_list = safe_attr(dcc.administrative_data, :dcc_software)
            return issues if software_list.nil?

            Array(safe_attr(software_list, :software)).each do |sw|
              release = Dcc::TypeGuards.has_attribute?(sw, :release) ? sw.release : nil
              next if release.nil? || release.empty?
              next if release.match?(PATTERN)

              issues << issue(
                severity: :error,
                message: "dcc:release '#{release}' does not match the expected format",
              )
            end

            issues
          end

          private

          def safe_attr(parent, attr)
            return nil unless parent && parent.is_a?(::Lutaml::Model::Serializable) && parent.class.attributes.key?(attr)

            parent.public_send(attr)
          end
        end
      end
    end
  end
end