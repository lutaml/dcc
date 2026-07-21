# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # Stub: validates that non-SI units (`|unit`) are declared in
        # `dcc:nonSIUnit` / `dcc:nonSIDefinition`. Requires D-SI parsing.
        class NonSiDeclaration < Base
          def check_on(_dcc)
            []
          end
        end
      end
    end
  end
end