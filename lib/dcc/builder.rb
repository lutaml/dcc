# frozen_string_literal: true

# `Dcc::Builder` provides a programmatic DSL for constructing DCC documents.
#
# @example
#   dcc = Dcc.build(version: 3) do
#     administrative_data do
#       core_data do
#         unique_identifier "urn:uuid:abc-123"
#         country_code "DE"
#         used_lang "en"
#         mandatory_lang "en"
#       end
#     end
#     measurement_results { }
#   end
module Dcc
  module Builder
    autoload :Session, "dcc/builder/session"
    autoload :Dsl, "dcc/builder/dsl"

    class << self
      # @param version [Integer, nil] major DCC version (default: 3).
      # @yield [Dcc::Builder::Session] builder session.
      # @return [Dcc::V2::DigitalCalibrationCertificate, Dcc::V3::DigitalCalibrationCertificate]
      def call(version: 3, &block)
        ::Dcc.load_all!
        session = Session.new(version: version)
        session.instance_eval(&block) if block_given?
        session.build
      end
    end
  end
end