# frozen_string_literal: true

module Dcc::V3
  class StringWithLang < CommonElements
    include ::Dcc::Base::StringWithLang
  end
  Configuration.register_model(StringWithLang, id: :content)
end
