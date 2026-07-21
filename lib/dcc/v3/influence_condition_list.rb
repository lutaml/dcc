# frozen_string_literal: true

module Dcc::V3
  class InfluenceConditionList < CommonElements
    include ::Dcc::Base::InfluenceConditionList
  end
  Configuration.register_model(InfluenceConditionList, id: :influenceConditions)
end
