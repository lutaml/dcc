# frozen_string_literal: true

module Dcc::V2
  class Formula < CommonElements
    include ::Dcc::Base::Formula
  end
  Configuration.register_model(Formula, id: :formula)
end
