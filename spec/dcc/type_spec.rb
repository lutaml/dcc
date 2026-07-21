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
        .to raise_error(Lutaml::Model::Type::InvalidValueError, /whitespace not allowed/)
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
      expect(described_class.serialize([BigDecimal("1"), BigDecimal("2"), BigDecimal("3")]))
        .to eq("1 2 3")
    end

    it "returns empty string for nil" do
      expect(described_class.serialize(nil)).to eq("")
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
      expect(described_class.cast("3.3.0").major).to eq(3)
      expect(described_class.cast("2.4.0").major).to eq(2)
    end
  end

  describe ".extract_major" do
    it "extracts major from a version string" do
      expect(described_class.extract_major("3.4.0-rc.2")).to eq(3)
    end
  end
end
