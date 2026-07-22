# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Dcc::Cli::Cli do
  let(:valid_file) { fixtures_path("dcclib", "valid.xml") }
  let(:invalid_file) { fixtures_path("dcclib", "invalid_schema.xml") }

  describe "validate xsd" do
    it "exits 0 on a valid file" do
      _exit_code, _output = capture_stdout_and_exit do
        described_class.start(["validate", "xsd", valid_file])
      end
      expect(_exit_code).to eq(0)
    end

    it "exits 1 on an invalid file" do
      _exit_code, _output = capture_stdout_and_exit do
        described_class.start(["validate", "xsd", invalid_file])
      end
      expect(_exit_code).to eq(1)
    end
  end

  describe "convert json" do
    it "writes JSON to stdout by default" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["convert", "json", valid_file])
      end
      expect(output).to include("1234")
    end

    it "writes to a file with --output" do
      outfile = Tempfile.new(["out", ".json"]).path
      capture_stdout_and_exit { described_class.start(["convert", "json", valid_file, "--output", outfile]) }
      payload = File.read(outfile)
      expect(payload).to include("1234")
      File.unlink(outfile)
    end
  end

  describe "extract files" do
    it "lists embedded files" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "files", valid_file])
      end
      expect(output).to include("test.txt")
    end
  end

  describe "inspect" do
    it "prints a summary" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["inspect", valid_file])
      end
      expect(output).to match(/Schema version:.*3\.3\.0/)
    end
  end

  describe "version" do
    it "prints the gem version" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["version"])
      end
      expect(output).to include("dcc 0.2.0")
    end
  end

  describe "diff" do
    it "compares two files" do
      expect do
        capture_stdout_and_exit { described_class.start(["diff", valid_file, valid_file]) }
      end.not_to raise_error
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = ::StringIO.new
    yield
  ensure
    captured = $stdout.string
    $stdout = original_stdout
    # Only return the captured string, not whatever the block evaluated to.
    raise "block returned a non-string; use capture_exit for that" unless captured.is_a?(::String)

    captured
  end

  def capture_stdout_and_exit
    original_stdout = $stdout
    $stdout = ::StringIO.new
    exit_code = nil
    begin
      yield
      exit_code = 0
    rescue SystemExit => e
      exit_code = e.status
    rescue StandardError
      exit_code = 1
      raise
    ensure
      captured = $stdout.string
      $stdout = original_stdout
    end
    [exit_code, captured]
  end

  def capture_exit
    original_stdout = $stdout
    $stdout = ::StringIO.new
    exit_code = nil
    begin
      yield
      exit_code = 0
    rescue SystemExit => e
      exit_code = e.status
    rescue StandardError => e
      exit_code = 1
      raise e
    ensure
      @captured_stdout = $stdout.string
      $stdout = original_stdout
    end
    exit_code
  end

  attr_reader :captured_stdout
end