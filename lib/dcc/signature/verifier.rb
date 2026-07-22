# frozen_string_literal: true

require "moxml"
require "openssl"

module Dcc
  module Signature
    # `Dcc::Signature::Verifier` validates a signed DCC using moxml's
    # native Signature module.
    module Verifier
      class << self
        # @param xml [String] signed DCC XML.
        # @param ca_cert_pem [String] PEM-encoded certificate or public key.
        # @return [Dcc::Signature::Result]
        def call(xml, ca_cert_pem:)
          ctx = ::Moxml.new(::Lutaml::Model::Config.xml_adapter_type)
          doc = ctx.parse(xml)

          key = load_key(ca_cert_pem)
          result = ::Moxml::Signature.verify(
            context: ctx,
            document: doc,
            key: key,
          )

          ::Dcc::Signature::Result.new(
            valid: result.valid?,
            certificate_pem: ca_cert_pem,
            signed_xml: doc.to_xml,
          )
        end

        private

        def load_key(pem)
          begin
            ::OpenSSL::X509::Certificate.new(pem).public_key
          rescue ::OpenSSL::X509::CertificateError
            ::OpenSSL::PKey::RSA.new(pem)
          end
        end
      end
    end
  end
end