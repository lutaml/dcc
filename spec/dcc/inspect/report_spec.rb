# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Inspect::Report do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:dcc) { Dcc.parse(xml) }
  subject(:report) { described_class.call(dcc) }

  before { Dcc::V3.load_all! }

  describe "#to_s" do
    it "produces a multi-line summary" do
      out = report.to_s
      expect(out).to include("DCC Inspection Report")
      expect(out).to include("Schema version:     3.3.0")
      expect(out).to include("Unique identifier:  1234")
      expect(out).to include("Country:            DE")
    end

    it "counts embedded files" do
      expect(report.embedded_file_count).to be >= 1
    end

    it "counts measurement results" do
      expect(report.measurement_result_count).to eq(1)
    end

    it "counts items" do
      expect(report.item_count).to eq(1)
    end
  end

  describe "#to_json" do
    it "produces valid JSON with the report fields" do
      payload = ::JSON.parse(report.to_json)
      expect(payload["unique_identifier"]).to eq("1234")
      expect(payload["item_count"]).to eq(1)
    end
  end
end