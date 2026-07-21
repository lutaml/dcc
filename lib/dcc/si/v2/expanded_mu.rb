# frozen_string_literal: true

module Dcc::Si::V2
  class ExpandedMU < CommonElements
    include ::Dcc::Si::Base::ExpandedMU
  end
  Configuration.register_model(ExpandedMU, id: :expandedMU)
end
