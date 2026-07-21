# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Cli::Formatters do
  describe ".print_files" do
    it "prints a table with no files message" do
      expect { described_class.print_files([]) }.to output(/no embedded files/).to_stdout
    end

    it "prints a table with file details" do
      Dcc::V3.load_all!
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      files = Dcc::Extract::File.each(dcc)
      expect { described_class.print_files(files) }.to output(/test\.txt/).to_stdout
    end
  end

  describe ".print" do
    it "uses to_s by default" do
      result = Dcc::Validate::Result.new(issues: [], source: "xsd")
      expect { described_class.print(result) }.to output(/OK/).to_stdout
    end

    it "switches to JSON on --format json" do
      result = Dcc::Validate::Result.new(issues: [], source: "xsd")
      expect { described_class.print(result, format: "json") }
        .to output(/^\{/).to_stdout
    end
  end
end