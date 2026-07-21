# frozen_string_literal: true

module Dcc::V2
  class InfluenceConditionList < CommonElements
    include ::Dcc::Base::InfluenceConditionList
  end
  Configuration.register_model(InfluenceConditionList, id: :influenceConditions)
end
