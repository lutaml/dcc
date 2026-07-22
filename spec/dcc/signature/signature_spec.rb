# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Signature do
  describe Dcc::Signature::Result do
    it "renders valid result" do
      r = described_class.new(valid: true, certificate_pem: "TEST")
      expect(r.valid?).to be(true)
      expect(r.to_s).to include("valid")
    end

    it "renders invalid result" do
      r = described_class.new(valid: false)
      expect(r.valid?).to be(false)
      expect(r.to_s).to include("INVALID")
    end

    it "produces JSON" do
      require "json"
      r = described_class.new(valid: true, certificate_pem: "PEM")
      payload = JSON.parse(r.to_json)
      expect(payload["valid"]).to be(true)
    end
  end

  describe Dcc::Signature::Signer do
    let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
    let(:key_pem) { File.read(fixtures_path("dcclib", "certs", "cert.key")) }
    let(:cert_pem) { File.read(fixtures_path("dcclib", "certs", "cert.pem")) }

    it "signs a DCC document" do
      signed = described_class.call(xml, cert_pem: cert_pem, key_pem: key_pem)
      expect(signed).to include("Signature")
      expect(signed).to include("SignatureValue")
    end
  end

  describe Dcc::Signature::Verifier do
    let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
    let(:key_pem) { File.read(fixtures_path("dcclib", "certs", "cert.key")) }
    let(:cert_pem) { File.read(fixtures_path("dcclib", "certs", "cert.pem")) }

    it "verifies a freshly signed document" do
      signed = Dcc::Signature::Signer.call(xml, cert_pem: cert_pem, key_pem: key_pem)
      result = described_class.call(signed, ca_cert_pem: cert_pem)
      expect(result.valid?).to be(true)
    end
  end
end