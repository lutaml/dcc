# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Extract::File do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:dcc) { Dcc.parse(xml) }

  before do
    Dcc::V3.load_all!
  end

  describe ".each" do
    it "finds the embedded test.txt file in valid.xml" do
      files = described_class.each(dcc)
      expect(files.size).to be >= 1
      test = files.first
      expect(test.file_name).to eq("test.txt")
      expect(test.mime_type).to eq("text/plain")
      expect(test.data).to eq("Test\n")
    end

    it "iterates with a block" do
      seen = []
      described_class.each(dcc) { |f| seen << f.file_name }
      expect(seen).to include("test.txt")
    end
  end

  describe ".at" do
    it "returns the file at the given index" do
      f = described_class.at(dcc, 0)
      expect(f).to be_a(described_class)
    end
  end

  describe ".in_ring" do
    it "filters by ring" do
      files = described_class.in_ring(dcc, ring: Dcc::Extract::Ring::ADMINISTRATIVE_DATA)
      expect(files.map(&:file_name)).to include("test.txt")
    end
  end

  describe "#text?" do
    it "detects textual payloads" do
      files = described_class.each(dcc)
      expect(files.first.text?).to be(true)
    end
  end
end

RSpec.describe Dcc::Extract::Ring do
  it "exposes the four canonical ring constants" do
    expect(described_class::ALL).to contain_exactly(
      :administrativeData,
      :measurementResults,
      :comment,
      :document,
    )
  end

  describe ".normalize" do
    it "returns canonical symbol for known rings" do
      expect(described_class.normalize("administrativeData")).to eq(:administrativeData)
      expect(described_class.normalize(:document)).to eq(:document)
    end

    it "returns nil for unknown values" do
      expect(described_class.normalize("foo")).to be_nil
    end
  end
end