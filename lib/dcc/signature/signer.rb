# frozen_string_literal: true

require "moxml"
require "openssl"

module Dcc
  module Signature
    # `Dcc::Signature::Signer` creates an enveloped XMLDSig signature over
    # a DCC document using RSA-SHA-256 with exclusive C14N. Uses moxml's
    # native Signature module.
    module Signer
      EXC_C14N = "http://www.w3.org/2001/10/xml-exc-c14n#"
      RSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      SHA256 = "http://www.w3.org/2001/04/xmlenc#sha256"
      ENVELOPED = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"

      class << self
        # @param xml_or_dcc [String, Lutaml::Model::Serializable] the DCC.
        # @param cert_pem [String] PEM-encoded signing certificate.
        # @param key_pem [String] PEM-encoded private key.
        # @return [String] the signed XML document.
        def call(xml_or_dcc, cert_pem:, key_pem:)
          xml = xml_or_dcc.is_a?(::String) ? xml_or_dcc : xml_or_dcc.to_xml
          ctx = ::Moxml.new(::Lutaml::Model::Config.xml_adapter_type)
          doc = ctx.parse(xml)
          key = ::OpenSSL::PKey::RSA.new(key_pem)
          cert = ::OpenSSL::X509::Certificate.new(cert_pem)

          signature = ::Moxml::Signature.sign(
            context: ctx,
            document: doc,
            key: key,
            certificate: cert,
            signature_method: RSA_SHA256,
            canonicalization_method: EXC_C14N,
            digest_method: SHA256,
            reference_uri: "",
            transforms: [ENVELOPED],
          )

          serialized = ::Moxml::Signature::Serializer
                         .new(context: ctx).serialize(signature)
          doc.root.add_child(serialized.root)
          doc.to_xml
        end
      end
    end
  end
end