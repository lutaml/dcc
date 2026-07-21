# frozen_string_literal: true

module Dcc::V2
  class Comment < CommonElements
    include ::Dcc::Base::Comment
  end
  Configuration.register_model(Comment, id: :comment)
end
