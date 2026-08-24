# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Cli::Formatters do
  describe ".print_files" do
    it "prints a table with no files message" do
      expect do
        described_class.print_files([])
      end.to output(/no embedded files/).to_stdout
    end

    it "prints a table with file details" do
      Dcc::V3.load_all!
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      files = Dcc::Extract::File.each(dcc)
      expect do
        described_class.print_files(files)
      end.to output(/test\.txt/).to_stdout
    end
  end

  # The gem does not depend on tty-table, so this is what most installs see.
  describe ".print_files without tty-table" do
    let(:files) do
      Dcc::V3.load_all!
      Dcc::Extract::File.each(
        Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))),
      )
    end

    before do
      allow(described_class).to receive(:table_available?).and_return(false)
    end

    it "still renders every file" do
      expect { described_class.print_files(files) }
        .to output(/test\.txt/).to_stdout
    end

    it "points at the nicer output on stderr, not stdout" do
      expect { described_class.print_files(files) }
        .to output(/gem install tty-table/).to_stderr
    end

    it "keeps stdout free of the hint so piped output stays data" do
      expect { described_class.print_files(files) }
        .not_to output(/gem install/).to_stdout
    end

    # A stderr that raises lands in the method's `rescue StandardError`,
    # which renders again. Anything parsing stdout would read the rows twice.
    it "renders each file once when the hint cannot be written" do
      allow(described_class).to receive(:warn).and_raise(Errno::EPIPE)

      expect { described_class.print_files(files) }
        .to output(satisfy { |out| out.scan("test.txt").size == 1 }).to_stdout
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
