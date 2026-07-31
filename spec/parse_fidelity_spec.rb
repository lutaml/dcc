# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# Parsing must not silently drop elements it claims to support. Each example
# counts an element in the source and in the re-serialized output; a mismatch
# means data was lost between parse and `to_xml`.
RSpec.describe Dcc, ".parse" do
  # A DCC v2 document reaches D-SI types through the :dsi_v1 and :dsi_v2
  # fallbacks, and those contexts exist only once their version module has been
  # loaded. Load both up front so every example stands on its own rather than
  # relying on an earlier one having populated them.
  before do
    Dcc::Si::V1.load_all!
    Dcc::Si::V2.load_all!
  end

  def element_count(xml, name)
    Nokogiri::XML(xml).xpath("//*[local-name()='#{name}']").size
  end

  def round_trip(relative)
    xml = File.read(fixtures_path(*relative.split("/")))
    Dcc.parser_for(Dcc.detect_version(xml)).load_all!
    [xml, Dcc.parse(xml).to_xml]
  end

  # Reported as a pair so one expectation covers both sides: a count that is
  # right on the way out but wrong on the way in proves nothing.
  def counts(relative, name)
    source, serialized = round_trip(relative)
    { in: element_count(source, name), out: element_count(serialized, name) }
  end

  describe "dcc:list" do
    {
      "dcclib/valid.xml" => 1,
      "dcclib/valid_formula.xml" => 2,
      "dcc_excel/example.xml" => 8,
    }.each do |fixture, expected|
      it "round-trips every list in #{fixture}" do
        expect(counts(fixture, "list")).to eq(in: expected, out: expected)
      end
    end
  end

  describe "dcc:quantity" do
    it "round-trips every quantity in dcc_excel/example.xml" do
      expect(counts("dcc_excel/example.xml", "quantity")).to eq(in: 20, out: 20)
    end
  end

  # dcc:mathml is a dcc:xmlType wrapper holding a foreign-namespace child, so
  # the MathML tree hangs one level below it rather than replacing it.
  describe "dcc:mathml" do
    let(:fixture) { "dcclib/valid_formula.xml" }

    it "round-trips the mathml wrapper" do
      expect(counts(fixture, "mathml")).to eq(in: 1, out: 1)
    end

    it "round-trips the ml:math child" do
      expect(counts(fixture, "math")).to eq(in: 1, out: 1)
    end

    it "keeps the MathML body" do
      expect(counts(fixture, "apply")).to eq(in: 5, out: 5)
    end
  end

  # D-SI v1 puts expandedUnc and coverageInterval directly under si:real, and
  # v2 still permits both as deprecated members of the same xs:choice.
  describe "si:expandedUnc" do
    {
      "dcc_examples/example.xml" => 10,
      "dcc_examples/siliziumkugel.xml" => 8,
    }.each do |fixture, expected|
      it "round-trips every expandedUnc in #{fixture}" do
        expect(counts(fixture, "expandedUnc"))
          .to eq(in: expected, out: expected)
      end
    end

    it "keeps the uncertainty value" do
      _, serialized = round_trip("dcc_examples/example.xml")
      expect(element_count(serialized, "coverageFactor")).to eq(10)
    end
  end

  describe "si:coverageInterval" do
    let(:real_xml) do
      <<~XML
        <si:real xmlns:si="https://ptb.de/si">
          <si:value>20.10</si:value>
          <si:unit>\\metre</si:unit>
          <si:coverageInterval>
            <si:standardUnc>0.02</si:standardUnc>
            <si:intervalMin>20.05</si:intervalMin>
            <si:intervalMax>20.15</si:intervalMax>
            <si:coverageProbability>0.95</si:coverageProbability>
          </si:coverageInterval>
        </si:real>
      XML
    end

    %i[V1 V2].each do |version|
      it "round-trips through Dcc::Si::#{version}::Real" do
        Dcc::Si.const_get(version).load_all!
        serialized = Dcc::Si.const_get(version)::Real.from_xml(real_xml).to_xml
        expect(element_count(serialized, "intervalMin")).to eq(1)
      end
    end
  end

  # A decimal XML list is one element holding space-separated values, so each
  # emitted realListXMLList must carry exactly one valueXMLList. Counting the
  # two against each other tests that directly, without depending on how many
  # lists survive parsing — quantities nested under a statement or metaData are
  # still dropped, because dcc:data is unmapped on Dcc::Base::Statement.
  describe "si:valueXMLList" do
    let(:serialized) { round_trip("dcclib/valid.xml").last }
    let(:texts) do
      Nokogiri::XML(serialized).xpath("//*[local-name()='valueXMLList']").map(&:text)
    end

    it "emits one valueXMLList per realListXMLList" do
      expect(texts.size).to eq(element_count(serialized, "realListXMLList"))
    end

    it "emits at least one list" do
      expect(texts).not_to be_empty
    end

    it "emits space-separated decimals rather than Ruby array literals" do
      expect(texts).to all(match(/\A-?[\d.]+( -?[\d.]+)*\z/))
    end

    it "preserves the original values verbatim" do
      expect(texts).to include("306.248 373.121 448.253 523.319 593.154")
    end
  end
end
