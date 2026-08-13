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

    # The evaluator slices bindings to the names a formula references,
    # so `-v TYPO=1` reached nothing and the run printed the unchanged
    # defaults and reported success.
    describe "an override no formula references" do
      let(:run) { extract_formulae(formula_file, "-v", "TYPO=1") }

      it "exits nonzero" do
        expect(run.first).to eq(1)
      end

      it "does not print the default values as if nothing were wrong" do
        expect(run.last).not_to include("100.0225")
      end
    end

    # A formula that cannot be evaluated used to abort the command from
    # outside the loop, after its header had already been printed, so
    # every other formula's output went with it.
    describe "one formula that cannot be evaluated" do
      # The Tempfile object, not its path: the object is what keeps the
      # file on disk.
      let(:document) { temp_document(broken_first, "dcc-two-formulae") }

      after { document.unlink }

      it "still prints the formula that works" do
        _status, output = extract_formulae(document.path)

        expect(output).to include("100.0225", "138.5392643225")
      end

      it "does not leave a bare header on stdout for the one that failed" do
        _status, output = extract_formulae(document.path)

        expect(output).not_to include("Broken(T)")
      end

      it "exits nonzero" do
        status, = extract_formulae(document.path)

        expect(status).to eq(1)
      end

      # Kernel#warn prints nothing when warnings are off, so `warn` here
      # left a RUBYOPT=-W0 user with exit 1 and no explanation.
      it "explains itself on stderr even with warnings disabled" do
        expect(silenced_stderr { extract_formulae(document.path) })
          .to include("No value for formula variable 'Q'")
      end
    end

    # An empty list gave the formula a result width of zero, so the body
    # never ran: a header, no values, and exit 0.
    describe "a formula variable with an empty list" do
      let(:document) { temp_document(empty_list, "dcc-empty-list") }

      after { document.unlink }

      it "exits nonzero instead of reporting success" do
        status, = extract_formulae(document.path)

        expect(status).to eq(1)
      end

      it "prints no values" do
        _status, output = extract_formulae(document.path)

        expect(output.lines.grep(/\A {2}-?\d/)).to be_empty
      end
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

  def extract_formulae(path, *flags)
    capture_stdout_and_exit do
      described_class.start(["extract", "formulae", path, *flags])
    end
  end

  # Runs the block with warnings off and stderr captured, which is what
  # `RUBYOPT=-W0` looks like from inside the process.
  def silenced_stderr
    original = $stderr
    $stderr = StringIO.new
    verbose = $VERBOSE
    $VERBOSE = nil
    yield
    $stderr.string
  ensure
    $VERBOSE = verbose
    $stderr = original
  end

  def temp_document(content, name)
    Tempfile.new([name, ".xml"]).tap do |file|
      file.write(content)
      file.close
    end
  end

  # The document's one formula, duplicated with the copy in front
  # renamed and pointed at a variable nothing binds.
  def broken_first
    src = File.read(fixtures_path("dcclib", "valid_formula.xml"))
    pattern = %r{<dcc:formula>\s*<dcc:mathml>.*?</dcc:mathml>\s*</dcc:formula>}m
    whole = src[pattern]
    broken = whole
      .sub("<ml:ci>R</ml:ci>", "<ml:ci>Broken</ml:ci>")
      .sub('<ml:ci xref="R0">R0</ml:ci>', "<ml:ci>Q</ml:ci>")
    src.sub(whole, broken + whole)
  end

  def empty_list
    File.read(fixtures_path("dcclib", "valid_formula.xml"))
      .sub("<si:valueXMLList>0 25 50 75 100</si:valueXMLList>",
           "<si:valueXMLList></si:valueXMLList>")
  end

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
