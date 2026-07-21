# frozen_string_literal: true

module Dcc
  module V3
    module Configuration
      extend ::Dcc::ContextConfiguration

      CONTEXT_ID = :dcc_v3

      # V3 DCC imports D-SI v2.x for quantity expressions. Returned as
      # instance method (becomes class method via `extend`).
      def fallback_contexts
        [:dsi_v2, :default]
      end
    end
  end
end
