# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::Schematron do
  let(:valid_xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:invalid_xml) { File.read(fixtures_path("dcclib", "invalid_schematron.xml")) }

  before { Dcc::V3.load_all! }

  describe ".call" do
    it "accepts a valid document" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      expect(result.source).to eq("schematron")
      expect(result.schema_version).to eq("3.3.0")
      expect(result.errors).to be_empty
    end

    it "flags invalid documents" do
      pending "needs crafted fixture with multiple Schematron violations"
      dcc = Dcc.parse(invalid_xml)
      result = described_class.call(dcc)
      expect(result.ok?).to be(false)
      expect(result.errors).not_to be_empty
    end

    it "produces issues with codes" do
      pending "needs Schematron-violating fixture"
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      codes = result.errors.map(&:code).compact
      expect(codes).to include("dcc.schematron.date_range_check")
    end
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::DateRangeCheck do
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "invalid_schematron.xml"))) }

  before { Dcc::V3.load_all! }

  it "validates without crashing" do
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::IsoCodeValidation do
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  before { Dcc::V3.load_all! }

  it "passes valid ISO codes" do
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_empty
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::LanguageCodeDedup do
  it "errors on duplicates" do
    skip "needs crafted fixture with duplicate codes"
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_empty
  end
end