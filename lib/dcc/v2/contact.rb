# frozen_string_literal: true

module Dcc::V2
  class Contact < CommonElements
    include ::Dcc::Base::Contact
  end
  Configuration.register_model(Contact, id: :contact)
end
