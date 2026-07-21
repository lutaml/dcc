# frozen_string_literal: true

module Dcc::V2
  class Text < CommonElements
    include ::Dcc::Base::Text
  end
  Configuration.register_model(Text, id: :text)
end
