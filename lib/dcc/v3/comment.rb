# frozen_string_literal: true

module Dcc::V3
  class Comment < CommonElements
    include ::Dcc::Base::Comment
  end
  Configuration.register_model(Comment, id: :comment)
end
