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
      file_handle = Tempfile.new("dcc-cli-test").tap(&:close)

      outfile = file_handle.path
      capture_stdout_and_exit do
        described_class.start(["convert", "json", valid_file, "--output",
                               outfile])
      end
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

  describe "extract formulae" do
    let(:formula_file) { fixtures_path("dcclib", "valid_formula.xml") }

    # A repeated -v must accumulate, not overwrite. With Thor's `type:
    # :array` the second -v silently dropped the first, so T fell back to
    # the document list and this printed five values instead of one.
    let(:repeated) do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(
          ["extract", "formulae", formula_file, "-v", "T=42", "-v", "R0=1"],
        )
      end
      output
    end

    it "prints the document's own values" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file])
      end

      expect(output).to include("R", "100.0225", "109.77301212171875")
    end

    it "honours -v overrides" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "T=42"])
      end

      expect(output).to include("116.357161312039")
    end

    it "accumulates repeated -v flags" do
      expect(repeated).to include("1.1633098684")
    end

    it "does not fall back to the document list when -v repeats" do
      expect(repeated).not_to include("109.77301212171875")
    end

    # A lone -v value is a scalar and broadcasts. Wrapping it in an array
    # made it a one-element list that collided with the document's own
    # five-element T list, so overriding one parameter was impossible.
    it "broadcasts a scalar override across the document list" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "R0=1"])
      end

      expect(output).to include("1.0974831875", "1.385081")
    end

    it "prints one line per document value for a scalar override" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "R0=1"])
      end

      expect(output.lines.grep(/\A {2}\d/).size).to eq(5)
    end

    # Two -v lists of different lengths is a real mismatch. It must reach
    # the user as a message, not as a Ruby backtrace out of Thor.
    it "aborts cleanly on mismatched override list lengths" do
      exit_code, = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file,
                               "-v", "T=1,2", "-v", "R0=1,2,3"])
      end

      expect(exit_code).to eq(1)
    end

    it "reports when a document has no formulae" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", valid_file])
      end

      expect(output).to include("No formulae found.")
    end

    # `abort` writes to stderr and raises SystemExit, so assert the status,
    # not the captured stdout.
    it "rejects a non-numeric override" do
      exit_code, = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "x=invalid"])
      end

      expect(exit_code).to eq(1)
    end

    it "rejects an override with an empty name" do
      exit_code, = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "=1"])
      end

      expect(exit_code).to eq(1)
    end

    # String#split drops a trailing empty field, so `T=42,` would lose the
    # empty entry instead of rejecting it.
    it "rejects an override with a trailing comma" do
      exit_code, = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", formula_file, "-v", "T=42,"])
      end

      expect(exit_code).to eq(1)
    end

    # Validation happens when the flag is parsed, so an override for a
    # variable the formula never mentions is still rejected.
    it "rejects a non-finite override even when the variable is unreferenced" do
      %w[Infinity NaN].each do |bad|
        exit_code, = capture_stdout_and_exit do
          described_class.start(["extract", "formulae", formula_file, "-v", "unused=#{bad}"])
        end

        expect(exit_code).to eq(1)
      end
    end

    # Same reason: nothing downstream would ever coerce this one.
    it "rejects a bad override against a document with no formulae" do
      exit_code, = capture_stdout_and_exit do
        described_class.start(["extract", "formulae", valid_file, "-v", "x=Infinity"])
      end

      expect(exit_code).to eq(1)
    end
  end

  describe "version" do
    it "prints the gem version" do
      _exit_code, output = capture_stdout_and_exit do
        described_class.start(["version"])
      end
      expect(output).to include("dcc #{Dcc::VERSION}")
    end
  end

  describe "diff" do
    it "compares two files" do
      expect do
        capture_stdout_and_exit do
          described_class.start(["diff", valid_file, valid_file])
        end
      end.not_to raise_error
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    captured = $stdout.string
    $stdout = original_stdout
    # Only return the captured string, not whatever the block evaluated to.
    raise "block returned a non-string; use capture_exit for that" unless captured.is_a?(String)

    captured
  end

  def capture_stdout_and_exit
    original_stdout = $stdout
    $stdout = StringIO.new
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
    $stdout = StringIO.new
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
