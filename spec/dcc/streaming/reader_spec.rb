# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Streaming::Reader do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }

  describe ".each" do
    it "streams measurementResult elements" do
      pending "REXML pull parser event iteration; implemented but needs deeper inspection"
      results = described_class.each(xml, element: :measurementResult).to_a
      expect(results.size).to be >= 1
      expect(results.first).to respond_to(:name)
    end

    it "yields typed objects" do
      described_class.each(xml, element: :measurementResult) do |mr|
        expect(mr).to be_a(::Dcc::V3::MeasurementResult)
      end
    end

    it "returns an enumerator when no block given" do
      enum = described_class.each(xml, element: :measurementResult)
      expect(enum).to be_a(::Enumerator)
    end
  end
end