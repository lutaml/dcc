# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:stringWithLangType` — single localized string with an optional
    # `xml:lang` attribute. Used inside `dcc:textType` and many other types.
    module StringWithLang
      def self.included(klass)
        klass.class_eval do
          attribute :value, :string, collection: true
          attribute :lang, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "content"
            mixed_content
            map_content to: :value
            map_attribute "lang", to: :lang
          end
        end
      end
    end
  end
end
