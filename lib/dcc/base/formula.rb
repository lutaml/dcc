# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:formulaType` — formula expression. v3.4 supports both `latex` and
    # `mathml`; older versions used `siunitx`. We accept all three as optional
    # attributes so old and new documents round-trip.
    module Formula
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :latex, :string
          attribute :mathml, :string
          attribute :siunitx, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "formula"
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "latex", to: :latex
            map_element "mathml", to: :mathml
            map_element "siunitx", to: :siunitx
          end
        end
      end
    end
  end
end
