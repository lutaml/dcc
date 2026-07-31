# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::Schematron do
  let(:valid_xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:invalid_xml) do
    File.read(fixtures_path("dcclib", "invalid_schematron.xml"))
  end

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
  let(:dcc) do
    Dcc.parse(File.read(fixtures_path("dcclib", "invalid_schematron.xml")))
  end

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

RSpec.describe Dcc::Validate::Schematron::Rules::UncertaintyConsistency do
  before { Dcc::Si::V2.load_all! }

  let(:rule) { described_class.new }

  def real_list(uncertainties, factors: "2")
    Dcc::Si::V2::RealListXmlList.from_xml(<<~XML)
      <si:realListXMLList xmlns:si="https://ptb.de/si">
        <si:valueXMLList>1 2 3 4 5</si:valueXMLList>
        <si:unitXMLList>\\kelvin</si:unitXMLList>
        <si:expandedUncXMLList>
          <si:uncertaintyXMLList>#{uncertainties}</si:uncertaintyXMLList>
          <si:coverageFactorXMLList>#{factors}</si:coverageFactorXMLList>
          <si:coverageProbabilityXMLList>0.95</si:coverageProbabilityXMLList>
        </si:expandedUncXMLList>
      </si:realListXMLList>
    XML
  end

  # D-SI broadcasts a single uncertainty across every value, the same way
  # unitXMLList broadcasts a single unit. PTB's own reference documents use
  # this far more often than a one-to-one list.
  it "accepts a single uncertainty broadcast over many values" do
    expect(rule.check_on(real_list("0.061"))).to be_empty
  end

  it "accepts an uncertainty per value" do
    list = real_list("0.1 0.2 0.3 0.4 0.5", factors: "2 2 2 2 2")
    expect(rule.check_on(list)).to be_empty
  end

  # PTB ships a document pairing nine uncertainties with one shared coverage
  # factor, so each list decides broadcast independently of its siblings.
  it "accepts a per-value list beside a broadcast sibling" do
    list = real_list("0.1 0.2 0.3 0.4 0.5", factors: "2")
    expect(rule.check_on(list)).to be_empty
  end

  it "reports a sibling list that neither matches nor broadcasts" do
    issues = rule.check_on(real_list("0.061", factors: "2 2 2"))
    expect(issues.map(&:message))
      .to include(a_string_matching(/coverageFactorXMLList count \(3\)/))
  end

  it "reports an uncertainty count that neither matches nor broadcasts" do
    issues = rule.check_on(real_list("0.1 0.2"))
    expect(issues.map(&:message))
      .to include(a_string_matching(/uncertaintyXMLList count \(2\)/))
  end
end
