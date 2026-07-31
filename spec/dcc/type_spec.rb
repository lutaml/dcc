# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Type::IsoCountryCode do
  describe ".cast" do
    it "accepts valid 2-letter uppercase codes" do
      expect(described_class.cast("DE")).to eq("DE")
      expect(described_class.cast("US")).to eq("US")
    end

    it "returns nil for nil/empty" do
      expect(described_class.cast(nil)).to be_nil
      expect(described_class.cast("")).to be_nil
    end

    it "returns nil for non-String inputs (graceful)" do
      expect(described_class.cast(123)).to be_nil
    end

    it "raises InvalidValueError for malformed codes" do
      expect { described_class.cast("de") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError, /country code/)
      expect { described_class.cast("DEU") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError)
      expect { described_class.cast("D") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError)
    end
  end
end

RSpec.describe Dcc::Type::IsoLanguageCode do
  describe ".cast" do
    it "accepts valid 2-letter lowercase codes" do
      expect(described_class.cast("en")).to eq("en")
      expect(described_class.cast("de")).to eq("de")
    end

    it "returns nil for nil/empty" do
      expect(described_class.cast(nil)).to be_nil
    end

    it "raises InvalidValueError for malformed codes" do
      expect { described_class.cast("EN") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError, /language code/)
      expect { described_class.cast("eng") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError)
    end
  end
end

RSpec.describe Dcc::Type::SiUnit do
  describe ".cast" do
    it "accepts siunitx expressions" do
      expect(described_class.cast("\\kelvin")).to eq("\\kelvin")
      expect(described_class.cast("\\meter\\per\\second")).to eq("\\meter\\per\\second")
    end

    it "raises InvalidValueError when whitespace is present" do
      expect { described_class.cast("\\meter per second") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError,
                        /whitespace not allowed/)
    end
  end
end

RSpec.describe Dcc::Type::Base64Binary do
  describe ".cast / .serialize" do
    it "passes through base64 strings unchanged (preserves round-trip)" do
      expect(described_class.cast("VGVzdAo=")).to eq("VGVzdAo=")
      expect(described_class.serialize("VGVzdAo=")).to eq("VGVzdAo=")
    end

    it "returns nil for nil" do
      expect(described_class.cast(nil)).to be_nil
      expect(described_class.serialize(nil)).to be_nil
    end
  end

  describe ".decode" do
    it "decodes base64 to binary" do
      expect(described_class.decode("VGVzdAo=")).to eq("Test\n")
      expect(described_class.decode("VGVzdAo=").encoding).to eq(Encoding::BINARY)
    end

    it "returns empty string for nil/invalid" do
      expect(described_class.decode(nil)).to eq("")
      expect(described_class.decode("not-base64!@#")).to eq("")
    end
  end

  describe ".encode" do
    it "encodes binary to base64" do
      expect(described_class.encode("Test\n")).to eq("VGVzdAo=")
    end
  end
end

RSpec.describe Dcc::Type::DecimalXmlList do
  describe ".cast" do
    it "splits a whitespace-separated list into BigDecimals" do
      result = described_class.cast("306 373 448")
      expect(result).to all(be_a(BigDecimal))
      expect(result.map(&:to_i)).to eq([306, 373, 448])
    end

    it "returns empty array for empty string" do
      expect(described_class.cast("")).to eq([])
    end

    it "returns empty array for whitespace-only string" do
      expect(described_class.cast("   ")).to eq([])
    end

    it "passes through arrays of BigDecimal" do
      arr = [BigDecimal("1.5"), BigDecimal("2.5")]
      expect(described_class.cast(arr)).to eq(arr)
    end
  end

  describe ".serialize" do
    it "joins values with single spaces" do
      expect(described_class.serialize([BigDecimal(1), BigDecimal(2),
                                        BigDecimal(3)]))
        .to eq("1 2 3")
    end

    it "returns empty string for nil" do
      expect(described_class.serialize(nil)).to eq("")
    end
  end

  # `to_ary` keeps equality symmetric: without it `Array#==` short-circuits to
  # false and the answer depends on which side the list is written on.
  describe "equality with a plain Array" do
    let(:values) { described_class.cast("0.1 0.2") }
    let(:array) { [BigDecimal("0.1"), BigDecimal("0.2")] }

    it "compares equal with the list on the left" do
      expect(values).to eq(array)
    end

    it "compares equal with the array on the left" do
      expect(array).to eq(values)
    end

    it "is not equal to a different list" do
      expect(values).not_to eq([BigDecimal("0.1"), BigDecimal("0.3")])
    end

    it "is not equal to an unrelated object" do
      expect(values).not_to eq("0.1 0.2")
    end

    # `hash` and `eql?` travel with `==`, or a list stops deduplicating.
    it "deduplicates equal lists" do
      expect([values, described_class.cast("0.1 0.2")].uniq.size).to eq(1)
    end

    it "hashes equal lists alike" do
      expect(values.hash).to eq(described_class.cast("0.1 0.2").hash)
    end

    # `eql?` is what Hash pairs with `hash`, so it stays stricter than `==`.
    # An equal Array hashes the same, and admitting it here would make lookup
    # depend on which of the two was used as the key.
    it "is eql? to an equal list" do
      expect(values).to eql(described_class.cast("0.1 0.2"))
    end

    it "is not eql? to an equal Array" do
      expect(values).not_to eql(array)
    end

    it "does not answer to an Array key" do
      expect({ values => 1 }[array]).to be_nil
    end
  end

  describe "list reading" do
    let(:values) { described_class.cast("0.1 0.2 0.3") }

    it "reports its length" do
      expect(values.length).to eq(3)
    end

    it "knows when it is empty" do
      expect(described_class.cast("")).to be_empty
    end

    it "returns the last entry" do
      expect(values.last).to eq(BigDecimal("0.3"))
    end

    # `join` must agree with `to_s`; delegating it to the BigDecimals would
    # re-emit the scientific notation the wire form exists to avoid.
    it "joins the serialized decimals" do
      expect(values.join(" ")).to eq("0.1 0.2 0.3")
    end

    it "joins on a given separator" do
      expect(values.join("; ")).to eq("0.1; 0.2; 0.3")
    end

    it "enumerates without a block" do
      expect(values.each).to be_a(Enumerator)
    end
  end

  # YAML must carry the wire form, not a Ruby object tag that `safe_load`
  # refuses to read back. `dcc convert yaml` is a shipped command.
  describe "YAML round-trip" do
    let(:yaml) { described_class.cast("0.072 0.089").to_yaml }

    it "dumps the space-separated wire form" do
      expect(YAML.safe_load(yaml)).to eq("0.072 0.089")
    end

    it "casts back to an equal list" do
      expect(described_class.cast(YAML.safe_load(yaml)))
        .to eq(described_class.cast("0.072 0.089"))
    end
  end

  # A decimal XML list is one element holding space-separated values. If the
  # cast result looks like a collection to lutaml-model, the list is split into
  # one element per value, each rendering a Ruby array literal.
  describe "round-trip through a model attribute" do
    before { Dcc::Si::V2.load_all! }

    let(:xml) do
      <<~XML
        <si:realListXMLList xmlns:si="https://ptb.de/si">
          <si:valueXMLList>0.072 0.089 0.107 -0.009 -0.084</si:valueXMLList>
          <si:unitXMLList>\\kelvin</si:unitXMLList>
        </si:realListXMLList>
      XML
    end

    let(:serialized) { Nokogiri::XML(Dcc::Si::V2::RealListXmlList.from_xml(xml).to_xml) }
    let(:emitted) { serialized.xpath("//*[local-name()='valueXMLList']") }

    it "emits exactly one valueXMLList element" do
      expect(emitted.size).to eq(1)
    end

    it "emits the values as space-separated decimals" do
      expect(emitted.first.text).to eq("0.072 0.089 0.107 -0.009 -0.084")
    end
  end
end

RSpec.describe Dcc::Type::SchemaVersion do
  describe ".cast" do
    it "accepts valid semver strings" do
      expect(described_class.cast("3.3.0")).to eq("3.3.0")
      expect(described_class.cast("3.4.0-rc.2")).to eq("3.4.0-rc.2")
    end

    it "returns nil for nil/empty" do
      expect(described_class.cast(nil)).to be_nil
      expect(described_class.cast("")).to be_nil
    end

    it "raises InvalidValueError for malformed versions" do
      expect { described_class.cast("3.x") }
        .to raise_error(Lutaml::Model::Type::InvalidValueError, /schemaVersion/)
    end
  end

  describe "#major" do
    it "extracts the major number" do
      expect(described_class.extract_major("3.3.0")).to eq(3)
      expect(described_class.extract_major("2.4.0")).to eq(2)
    end
  end

  describe ".extract_major" do
    it "extracts major from a version string" do
      expect(described_class.extract_major("3.4.0-rc.2")).to eq(3)
    end
  end
end
