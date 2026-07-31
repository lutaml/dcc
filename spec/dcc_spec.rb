# frozen_string_literal: true

require "spec_helper"

$LOAD_PATH.unshift(fixtures_path("plugins"))

RSpec.describe Dcc do
  describe ".parser_for" do
    it "returns Dcc::V2 for version 2" do
      expect(Dcc.parser_for(2)).to eq(Dcc::V2)
    end

    it "returns Dcc::V3 for version 3" do
      expect(Dcc.parser_for(3)).to eq(Dcc::V3)
    end

    it "raises UnknownVersionError for unsupported versions" do
      expect { Dcc.parser_for(99) }
        .to raise_error(Dcc::UnknownVersionError, /Unsupported DCC version/)
    end
  end

  describe ".detect_version" do
    it "returns 3 for v3.x schemaVersion" do
      expect(Dcc.detect_version('<dcc:digitalCalibrationCertificate schemaVersion="3.3.0"/>'))
        .to eq(3)
    end

    it "returns 2 for v2.x schemaVersion" do
      expect(Dcc.detect_version('<dcc:digitalCalibrationCertificate schemaVersion="2.3.0"/>'))
        .to eq(2)
    end

    it "defaults to 3 when schemaVersion is missing" do
      expect(Dcc.detect_version("<dcc:digitalCalibrationCertificate/>")).to eq(3)
    end
  end

  describe ".read_input" do
    it "returns strings unchanged" do
      expect(Dcc.read_input("hello")).to eq("hello")
    end

    it "reads from StringIO" do
      io = StringIO.new("from-io")
      expect(Dcc.read_input(io)).to eq("from-io")
    end

    it "reads from a File handle" do
      data = nil
      File.open(File.join(FIXTURES_DIR, "dcc_xsd", "example.xml")) do |f|
        data = Dcc.read_input(f)
      end
      expect(data).to include("digitalCalibrationCertificate")
    end
  end

  describe ".io_like?" do
    it "returns true for IO, StringIO, File" do
      expect(Dcc.io_like?(StringIO.new)).to be(true)
    end

    it "returns false for String, nil" do
      expect(Dcc.io_like?("plain")).to be(false)
      expect(Dcc.io_like?(nil)).to be(false)
    end
  end

  describe ".load_plugins" do
    before { Dcc::Plugin.reset! }
    after { Dcc::Plugin.reset! }

    it "maps a gem name to its entry-file path" do
      expect(described_class.load_plugins("dcc-version"))
        .to eq(["dcc/version"])
    end

    it "leaves a slash-separated path alone, hyphens included" do
      expect { described_class.load_plugins("dcc/nope-not-real") }
        .to raise_error(Dcc::PluginError, %r{require "dcc/nope-not-real"})
    end

    it "names the plugin when its entry file is missing" do
      expect { described_class.load_plugins("dcc-nope-not-real") }
        .to raise_error(Dcc::PluginError, /dcc-nope-not-real/)
    end

    it "names the path it tried when loading fails" do
      expect { described_class.load_plugins("dcc-nope-not-real") }
        .to raise_error(Dcc::PluginError, %r{dcc/nope/not/real})
    end

    # Only this example may load the fixture: `require` is idempotent per
    # process, so a second one would find nothing registered.
    it "requires the plugin so its declarations take effect" do
      described_class.load_plugins("dcc-sample_plugin")
      expect(Dcc::Plugin.all(:validators))
        .to include(DccSamplePlugin::SampleRule)
    end
  end
end
