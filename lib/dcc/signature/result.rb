# frozen_string_literal: true

module Dcc
  module Signature
    # Outcome of a signature verification. Carries the verified certificate,
    # validity flag, and the signed XML subtree (the only trustable part).
    class Result
      attr_reader :valid, :certificate_pem, :signed_xml

      def initialize(valid:, certificate_pem: nil, signed_xml: nil)
        @valid = valid
        @certificate_pem = certificate_pem
        @signed_xml = signed_xml
      end

      def valid?
        !!@valid
      end

      def to_s
        if valid?
          "Signature valid#{certificate_pem ? " (cert: #{certificate_pem.lines.first&.strip})" : ''}"
        else
          "Signature INVALID"
        end
      end

      def to_json(*_args)
        require "json"
        ::JSON.pretty_generate(
          valid: valid?,
          certificate_pem: certificate_pem,
          signed_xml_length: signed_xml&.length,
        )
      end

      def to_yaml(*_args)
        require "yaml"
        { valid: valid?, certificate_pem: certificate_pem }.to_yaml
      end
    end
  end
end