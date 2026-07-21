# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Signature do
  describe "soft-dependency" do
    it "is available because xmldsig is in the Gemfile" do
      require "xmldsig"
      expect(defined?(::Xmldsig)).to be_truthy
    end
  end

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
end