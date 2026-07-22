# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:formulaType` — formula expression. v3.4 supports both `latex`
    # and `mathml`; older versions used `siunitx`.
    #
    # The `mathml` attribute stores the raw MathML XML as a string for
    # round-trip serialization safety. Call `.mathml_object` to lazily
    # parse it into a typed `Mml::V3::Math` via the `mml` gem.
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

          # Lazily parse the raw MathML string into a typed Mml::V3::Math
          # object via the `mml` gem. Returns nil if mathml is empty.
          define_method(:mathml_object) do
            raw = mathml
            return nil unless raw && !raw.to_s.empty?

            ::Mml.parse(raw.to_s)
          rescue ::StandardError
            nil
          end
        end
      end
    end
  end
end