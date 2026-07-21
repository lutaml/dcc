# frozen_string_literal: true

module Dcc::V2
  class ByteData < CommonElements
    include ::Dcc::Base::ByteData
  end
  Configuration.register_model(ByteData, id: :byteData)
end
