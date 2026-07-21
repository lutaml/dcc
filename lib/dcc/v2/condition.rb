# frozen_string_literal: true

module Dcc::V2
  class Condition < CommonElements
    include ::Dcc::Base::Condition
  end
  Configuration.register_model(Condition, id: :influenceCondition)
end
