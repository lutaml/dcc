# frozen_string_literal: true

module Dcc::V2
  class Statement < CommonElements
    include ::Dcc::Base::Statement
  end
  Configuration.register_model(Statement, id: :statement)
end
