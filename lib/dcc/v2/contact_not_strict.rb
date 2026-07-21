# frozen_string_literal: true

module Dcc::V2
  class ContactNotStrict < CommonElements
    include ::Dcc::Base::ContactNotStrict
  end
  Configuration.register_model(ContactNotStrict, id: :contactNotStrict)
end
