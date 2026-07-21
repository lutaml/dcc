# frozen_string_literal: true

module Dcc
  module V2
    module Configuration
      extend ::Dcc::ContextConfiguration

      CONTEXT_ID = :dcc_v2

      # V2 DCC imports D-SI v1.x (registered as :dsi_v1). We also fall back
      # to :dsi_v2 for forward-compatible parsing.
      def self.fallback_contexts
        [:dsi_v1, :dsi_v2, :default]
      end
    end
  end
end
