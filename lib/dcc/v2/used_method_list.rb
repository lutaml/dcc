# frozen_string_literal: true

module Dcc::V2
  class UsedMethodList < CommonElements
    include ::Dcc::Base::UsedMethodList
  end
  Configuration.register_model(UsedMethodList, id: :usedMethods)
end
