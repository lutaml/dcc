# frozen_string_literal: true

module Dcc::V3
  class Mathml < CommonElements
    include ::Dcc::Base::Mathml
  end
  Configuration.register_model(Mathml, id: :mathml)
end
