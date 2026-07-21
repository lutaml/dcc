# frozen_string_literal: true

module Dcc::V3
  class XmlBlob < CommonElements
    include ::Dcc::Base::XmlBlob
  end
  Configuration.register_model(XmlBlob, id: :xml)
end
