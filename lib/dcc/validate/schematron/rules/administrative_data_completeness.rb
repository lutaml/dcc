# frozen_string_literal: true

module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that all required sections are present in
        # `dcc:administrativeData`: dccSoftware, coreData, items,
        # calibrationLaboratory, respPersons, customer.
        class AdministrativeDataCompleteness < Base
          REQUIRED_SECTIONS = {
            dcc_software: "dccSoftware",
            core_data: "coreData",
            items: "items",
            calibration_laboratory: "calibrationLaboratory",
            resp_persons: "respPersons",
            customer: "customer",
          }.freeze

          def check_on(dcc)
            issues = []
            return issues unless Dcc::TypeGuards.has_attribute?(dcc, :administrative_data)

            admin = dcc.administrative_data
            return [issue(severity: :error, message: "administrativeData is missing")] unless admin

            REQUIRED_SECTIONS.each do |attr, label|
              value = Dcc::TypeGuards.has_attribute?(admin, attr) ? admin.public_send(attr) : nil
              next unless value.nil? || ((value.is_a?(::String) || value.is_a?(::Array)) && value.empty?)

              issues << issue(
                severity: :error,
                message: "dcc:administrativeData/#{label} is missing",
              )
            end
            issues
          end
        end
      end
    end
  end
end