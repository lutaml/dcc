# frozen_string_literal: true

module Dcc::Si::V1
  class Hybrid < CommonElements
    include ::Dcc::Si::Base::Hybrid
  end
  Configuration.register_model(Hybrid, id: :hybrid)
end
