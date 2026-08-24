# frozen_string_literal: true

require "mml"

module Dcc
  module Base
    # `dcc:mathml` — a `dcc:xmlType` wrapper carrying a single foreign-namespace
    # child, which for a formula is `ml:math`. The MathML tree hangs below the
    # wrapper rather than replacing it.
    module Mathml
      # rubocop:disable Metrics/MethodLength -- one lutaml mapping block,
      # split the same way every sibling module in Dcc::Base is written.
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :math, ::Mml::V3::Math

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "mathml"
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "math", to: :math
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
