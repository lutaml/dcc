# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:comment` — wildcard (`xs:any namespace="##any"`) wrapper around
    # arbitrary XML. The contents are preserved as a raw XML string; lutaml-model
    # requires `map_all` to be the only mapping in a class, so the comment
    # element lives in its own class referenced by `DigitalCalibrationCertificate`.
    module Comment
      def self.included(klass)
        klass.class_eval do
          attribute :raw, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "comment"
            map_all to: :raw
          end
        end
      end
    end
  end
end
