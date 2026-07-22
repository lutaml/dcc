# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Convert::Json do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:dcc) { Dcc.parse(xml) }

  before do
    Dcc::V3.load_all!
  end

  describe ".call" do
    it "produces valid JSON" do
      result = described_class.call(dcc)
      expect(result.format).to eq(:json)
      expect(result.payload).to be_a(String)

      parsed = ::JSON.parse(result.payload)
      expect(parsed).to be_a(Hash)
    end

    it "includes key fields" do
      parsed = ::JSON.parse(described_class.call(dcc).payload)
      admin = parsed["administrativeData"]
      expect(admin["coreData"]["uniqueIdentifier"]).to eq("1234")
    end

    it "supports pretty and compact modes" do
      pretty = described_class.call(dcc, pretty: true).payload
      compact = described_class.call(dcc, pretty: false).payload
      expect(pretty.length).to be > compact.length
    end

    it "round-trips through JSON" do
      payload = described_class.call(dcc).payload
      parsed = ::JSON.parse(payload)
      admin = parsed["administrativeData"]
      expect(admin["coreData"]["countryCodeISO3166_1"]).to eq("DE")
    end
  end
end

RSpec.describe Dcc::Convert::Result do
  let(:payload) { '{"key":"value"}' }
  subject(:result) do
    described_class.new(format: :json, payload: payload, source_class: "Dcc::V3::DigitalCalibrationCertificate")
  end

  describe "#to_s" do
    it "returns the raw payload" do
      expect(result.to_s).to eq(payload)
    end
  end

  describe "#parsed" do
    it "parses JSON payload" do
      expect(result.parsed).to eq("key" => "value")
    end
  end
end