# frozen_string_literal: true

require "mml"

module Dcc
  module Base
    # `dcc:formulaType` — formula expression. Contains `latex` string,
    # `mathml` (a typed `Mml::V3::Math` model), or legacy `siunitx`.
    module Formula
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :latex, :string
          attribute :mathml, ::Mml::V3::Math
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