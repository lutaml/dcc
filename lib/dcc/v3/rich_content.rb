# frozen_string_literal: true

module Dcc::V3
  class RichContent < CommonElements
    include ::Dcc::Base::RichContent
  end
  Configuration.register_model(RichContent, id: :richContent)
end
