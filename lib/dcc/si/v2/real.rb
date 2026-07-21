# frozen_string_literal: true

module Dcc::Si::V2
  class Real < CommonElements
    include ::Dcc::Si::Base::Real
  end
  Configuration.register_model(Real, id: :real)
end
