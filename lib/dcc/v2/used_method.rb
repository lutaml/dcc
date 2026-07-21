# frozen_string_literal: true

module Dcc::V2
  class UsedMethod < CommonElements
    include ::Dcc::Base::UsedMethod
  end
  Configuration.register_model(UsedMethod, id: :usedMethod)
end
