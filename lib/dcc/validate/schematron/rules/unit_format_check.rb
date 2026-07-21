# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # Stub: validates unit format (no whitespace, list length matches
        # value list length). Requires D-SI parsing.
        class UnitFormatCheck < Base
          def check_on(_dcc)
            []
          end
        end
      end
    end
  end
end