# frozen_string_literal: true

module Dcc::Si::V2
  class StandardMU < CommonElements
    include ::Dcc::Si::Base::StandardMU
  end
  Configuration.register_model(StandardMU, id: :standardMU)
end
