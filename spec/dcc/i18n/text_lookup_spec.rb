# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::I18n::TextLookup do
  before { Dcc.load_all! }

  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  describe ".call" do
    it "returns the English content when requested" do
      mr = dcc.measurement_results.measurement_result.first
      result = described_class.call(mr.name, dcc: dcc, lang: "en")
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it "falls back to declared languages when lang is nil" do
      mr = dcc.measurement_results.measurement_result.first
      result = described_class.call(mr.name, dcc: dcc, lang: nil)
      expect(result).to be_a(String)
    end

    it "returns nil for missing text" do
      expect(described_class.call(nil)).to be_nil
    end
  end
end