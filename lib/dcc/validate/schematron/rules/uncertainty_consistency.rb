# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # Stub: validates consistency between value lists and uncertainty
        # lists (lists must have matching counts). Full D-SI parsing is
        # required to enumerate list contents; placeholder returns empty
        # until D-SI model is wired into quantities.
        class UncertaintyConsistency < Base
          def check_on(_dcc)
            []
          end
        end
      end
    end
  end
end