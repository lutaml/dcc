# frozen_string_literal: true

module Dcc::V3
  class UsedMethodList < CommonElements
    include ::Dcc::Base::UsedMethodList
  end
  Configuration.register_model(UsedMethodList, id: :usedMethods)
end
