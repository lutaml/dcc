# frozen_string_literal: true

module Dcc::V3
  class Identification < CommonElements
    include ::Dcc::Base::Identification
  end
  Configuration.register_model(Identification, id: :identification)
end
