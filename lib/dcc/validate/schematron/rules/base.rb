# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Schematron rule base. Concrete rules subclass this and implement
        # `#check_on(dcc)`. Each subclass declares its `severity`.
        class Base < ::Dcc::Validate::Schematron::Rule
        end
      end
    end
  end
end