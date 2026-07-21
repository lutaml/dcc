# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # Errors if any `dcc:statement` element appears under
        # `dcc:administrativeData`.
        class AdministrativeDataCompleteness < Base
        end
      end
    end
  end
end