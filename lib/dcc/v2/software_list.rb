# frozen_string_literal: true

module Dcc::V2
  class SoftwareList < CommonElements
    include ::Dcc::Base::SoftwareList
  end
  Configuration.register_model(SoftwareList, id: :softwareList)
end
