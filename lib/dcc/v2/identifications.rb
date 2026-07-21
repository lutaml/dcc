# frozen_string_literal: true

module Dcc::V2
  class Identifications < CommonElements
    include ::Dcc::Base::Identifications
  end
  Configuration.register_model(Identifications, id: :identifications)
end
