# frozen_string_literal: true

module Dcc
  module Signature
    # `Dcc::Signature::Signer` wraps an enveloped XMLDSig signature over a
    # DCC document using RSA-SHA-256. Requires the `xmldsig` gem.
    module Signer
      class << self
        # @param xml_or_dcc [String, Lutaml::Model::Serializable] the DCC.
        # @param cert_pem [String] PEM-encoded signing certificate.
        # @param key_pem [String] PEM-encoded private key.
        # @return [String] the signed XML document.
        def call(xml_or_dcc, cert_pem:, key_pem:)
          ensure_xmldsig!
          xml = xml_or_dcc.is_a?(::String) ? xml_or_dcc : xml_or_dcc.to_xml
          document = Xmldsig::XMLDoc.new(xml)
          document.sign(
            OpenSSL::PKey::RSA.new(key_pem),
            cert_pem,
          ).to_xml
        end

        private

        def ensure_xmldsig!
          return if defined?(::Xmldsig)

          require "xmldsig"
        rescue ::LoadError
          raise ::Dcc::MissingDependencyError.new(gem_name: "xmldsig", feature: "Dcc::Signature"),
                "xmldsig is required for XMLDSig signing"
        end
      end
    end
  end
end