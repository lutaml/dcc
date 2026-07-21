# frozen_string_literal: true

module Dcc
  module V2
    # V2 base class. All V2 element wrappers inherit from this so they get
    # `lutaml_default_register` returning `:dcc_v2` automatically.
    class CommonElements < ::Dcc::CommonElements
      def self.lutaml_default_register
        :dcc_v2
      end
    end
  end
end
