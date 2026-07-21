# frozen_string_literal: true

module Dcc::V3
  class Location < CommonElements
    include ::Dcc::Base::Location
  end
  Configuration.register_model(Location, id: :location)
end
