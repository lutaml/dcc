# frozen_string_literal: true

module Dcc::Si::V1
  # Deprecated v1 expandedUnc type — superseded by expandedMU in v2.
  # Kept so old fixtures parse without losing data.
  class ExpandedUnc < CommonElements
    attribute :uncertainty, :string
    attribute :coverage_factor, :string
    attribute :coverage_probability, :string
    attribute :distribution, :string

    xml do
      namespace ::Dcc::Namespace::Si
      element "expandedUnc"
      ordered
      map_element "uncertainty", to: :uncertainty
      map_element "coverageFactor", to: :coverage_factor
      map_element "coverageProbability", to: :coverage_probability
      map_element "distribution", to: :distribution
    end
  end
  Configuration.register_model(ExpandedUnc, id: :expandedUnc)
end
