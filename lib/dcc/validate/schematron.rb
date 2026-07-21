# frozen_string_literal: true

# `Dcc::Validate::Schematron` is the public Schematron validator. Calling
# `Dcc::Validate::Schematron.call(dcc)` runs the entire PTB rule profile
# and returns a `Dcc::Validate::Result`.
module Dcc
  module Validate
    module Schematron
      autoload :Profile, "dcc/validate/schematron/profile"
      autoload :Rules, "dcc/validate/schematron/rules"

      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Validate::Result]
        def call(dcc)
          Profile.call(dcc)
        end
      end
    end
  end
end