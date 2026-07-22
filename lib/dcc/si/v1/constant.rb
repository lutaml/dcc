# frozen_string_literal: true

module Dcc::Si::V1
  class Constant < CommonElements
    include ::Dcc::Si::Base::Constant
  end
  Configuration.register_model(Constant, id: :constant)
end
