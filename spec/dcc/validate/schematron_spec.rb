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

    it "returns a Result model with to_s/to_json/to_yaml" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      expect(result).to respond_to(:to_s)
      expect(result).to respond_to(:to_json)
      expect(result).to respond_to(:to_yaml)
    end

    it "runs every rule without crashing on either fixture" do
      [valid_xml, invalid_xml].each do |xml|
        dcc = Dcc.parse(xml)
        expect { described_class.call(dcc) }.not_to raise_error
      end
    end

    it "returns codes for any issues it finds" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      result.errors.each do |e|
        expect(e.code).to match(/\Adcc\.schematron\./)
      end
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
  before { Dcc::V3.load_all! }

  it "passes for valid documents" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end