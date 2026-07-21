# frozen_string_literal: true

module Dcc::Si::V2
  class Complex < CommonElements
    include ::Dcc::Si::Base::Complex
  end
  Configuration.register_model(Complex, id: :complex)
end
