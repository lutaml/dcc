# frozen_string_literal: true

module Dcc
  module Si
    # Base class for D-SI element wrappers. Subclassed per version with the
    # appropriate `lutaml_default_register`.
    class CommonElements < Lutaml::Model::Serializable
      def self.lutaml_default_register
        :dsi_v2
      end
    end
  end
end
