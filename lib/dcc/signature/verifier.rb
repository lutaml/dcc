# frozen_string_literal: true

module Dcc
  module Signature
    # `Dcc::Signature::Verifier` validates a signed DCC against a CA
    # certificate. The signed XML subtree is extracted so callers can
    # extract the trustworthy content.
    module Verifier
      class << self
        # @param xml [String] signed DCC XML.
        # @param ca_cert_pem [String] PEM-encoded CA certificate.
        # @return [Dcc::Signature::Result]
        def call(xml, ca_cert_pem:)
          ensure_xmldsig!
          document = Xmldsig::XMLDoc.new(xml)
          signed_xml = nil
          is_valid = document.validate(ca_cert_pem) do |signed_node|
            signed_xml = signed_node.to_xml
            true
          end
          ::Dcc::Signature::Result.new(
            valid: is_valid,
            certificate_pem: ca_cert_pem,
            signed_xml: signed_xml,
          )
        end

        private

        def ensure_xmldsig!
          return if defined?(::Xmldsig)

          require "xmldsig"
        rescue ::LoadError
          raise ::Dcc::MissingDependencyError.new(gem_name: "xmldsig", feature: "Dcc::Signature"),
                "xmldsig is required for XMLDSig verification"
        end
      end
    end
  end
end