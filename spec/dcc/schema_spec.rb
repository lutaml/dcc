# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Schema do
  describe ".path" do
    it "returns absolute paths under lib/dcc/schema/resources/" do
      path = Dcc::Schema.path("dcc/v3.3.0/dcc.xsd")
      expect(path).to end_with("lib/dcc/schema/resources/dcc/v3.3.0/dcc.xsd")
      expect(File.file?(path)).to be(true)
    end

    it "accepts array parts" do
      path = Dcc::Schema.path(%w[dsi v2.2.1 SI_Format.xsd])
      expect(File.file?(path)).to be(true)
    end
  end

  describe ".exists?" do
    it "returns true for known resources" do
      expect(Dcc::Schema.exists?("dcc/v3.3.0/dcc.xsd")).to be(true)
      expect(Dcc::Schema.exists?("dsi/v2.2.1/SI_Format.xsd")).to be(true)
      expect(Dcc::Schema.exists?("qudt/qudt.xsd")).to be(true)
      expect(Dcc::Schema.exists?("schematron/dcc.sch")).to be(true)
    end

    it "returns false for missing resources" do
      expect(Dcc::Schema.exists?("nonexistent.foo")).to be(false)
    end
  end

  describe ".read" do
    it "reads file contents" do
      content = Dcc::Schema.read("qudt/qudt.xsd")
      expect(content).to include("http://qudt.org/vocab/")
    end
  end

  describe Dcc::Schema::Version do
    it "lists 12 DCC versions" do
      expect(Dcc::Schema::Version::DCC_ALL.size).to eq(12)
      expect(Dcc::Schema::Version::DCC_ALL).to include("2.1.0", "3.3.0")
    end

    it "lists 6 D-SI versions" do
      expect(Dcc::Schema::Version::DSI_ALL.size).to eq(6)
      expect(Dcc::Schema::Version::DSI_ALL).to include("1.0.1", "2.2.1")
    end

    describe ".normalize" do
      it "strips a leading 'v'" do
        expect(Dcc::Schema::Version.normalize("v3.3.0")).to eq("3.3.0")
      end

      it "converts underscores to dots" do
        expect(Dcc::Schema::Version.normalize(:v3_3_0)).to eq("3.3.0")
      end

      it "returns nil for nil" do
        expect(Dcc::Schema::Version.normalize(nil)).to be_nil
      end
    end

    describe ".dcc?" do
      it "returns true for known DCC versions" do
        expect(Dcc::Schema::Version.dcc?("3.3.0")).to be(true)
        expect(Dcc::Schema::Version.dcc?(:v2_1_0)).to be(true)
      end

      it "returns false for unknown versions" do
        expect(Dcc::Schema::Version.dcc?("9.9.9")).to be(false)
      end
    end

    describe ".resolve_dcc" do
      it "returns the version when explicitly given" do
        expect(Dcc::Schema::Version.resolve_dcc("3.2.0")).to eq("3.2.0")
      end

      it "returns DCC_LATEST for 'latest'" do
        expect(Dcc::Schema::Version.resolve_dcc("latest")).to eq(Dcc::Schema::Version::DCC_LATEST)
      end

      it "auto-detects from XML when given :auto" do
        xml = '<dcc:digitalCalibrationCertificate schemaVersion="3.1.0"/>'
        expect(Dcc::Schema::Version.resolve_dcc("auto", xml: xml)).to eq("3.1.0")
      end

      it "raises UnknownVersionError for unknown versions" do
        expect { Dcc::Schema::Version.resolve_dcc("9.9.9") }
          .to raise_error(Dcc::UnknownVersionError, /Unknown DCC schema version/)
      end
    end

    describe ".major" do
      it "extracts the major number" do
        expect(Dcc::Schema::Version.major("3.3.0")).to eq(3)
        expect(Dcc::Schema::Version.major("2.4.0")).to eq(2)
      end
    end
  end
end
