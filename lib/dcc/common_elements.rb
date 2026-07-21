# frozen_string_literal: true

require "lutaml/model"

module Dcc
  # `Dcc::CommonElements` is the base class for all DCC element wrappers in a
  # version namespace. It provides the shared `lutaml_default_register`
  # override that version wrappers inherit, so they don't each have to declare
  # it themselves.
  #
  # Version modules (`Dcc::V2`, `Dcc::V3`) subclass this to define their
  # own `CommonElements` with a `lutaml_default_register` matching their
  # `CONTEXT_ID`.
  class CommonElements < Lutaml::Model::Serializable
    # Default context; version wrappers override this via subclassing.
    def self.lutaml_default_register
      :dcc_v3
    end
  end
end
