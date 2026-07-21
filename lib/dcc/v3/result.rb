# frozen_string_literal: true

module Dcc::V3
  class Result < CommonElements
    include ::Dcc::Base::Result
  end
  Configuration.register_model(Result, id: :result)
end
