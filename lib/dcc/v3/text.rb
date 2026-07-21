# frozen_string_literal: true

module Dcc::V3
  class Text < CommonElements
    include ::Dcc::Base::Text
  end
  Configuration.register_model(Text, id: :text)
end
