# frozen_string_literal: true

module Dcc::V3
  class Software < CommonElements
    include ::Dcc::Base::Software
  end
  Configuration.register_model(Software, id: :software)
end
