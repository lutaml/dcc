# frozen_string_literal: true

RSpec.describe Dcc::Extract::Formula::Parser do
  # Never assign a bare `Ast` constant in a spec file — it leaks to top
  # level and collides with the evaluator spec. Build nodes via a helper.
  def node(kind, **fields)
    Dcc::Extract::Formula::Ast.const_get(kind).new(**fields)
  end

  def parse(body)
    ns = 'xmlns:ml="http://www.w3.org/1998/Math/MathML"'
    xml = "<ml:math #{ns}>#{body}</ml:math>"
    described_class.call(Mml::V3::Math.from_xml(xml))
  end

  def num(value)
    node(:Number, value: BigDecimal(value))
  end

  describe "operand order" do
    let(:times) do
      "<ml:apply><ml:times/><ml:ci>R0</ml:ci><ml:cn>2</ml:cn></ml:apply>"
    end
    let(:body) { parse(times).body }

    it "keeps the operator" do
      expect(body.operator).to eq(:*)
    end

    it "keeps operands in document order across mixed child types" do
      expect(body.operands).to eq([node(:Variable, name: "R0"), num("2")])
    end
  end

  describe "declare/lambda" do
    let(:declare) do
      <<~ML
        <ml:declare type="fn">
          <ml:ci>R</ml:ci>
          <ml:lambda>
            <ml:bvar><ml:ci>T</ml:ci></ml:bvar>
            <ml:apply><ml:plus/><ml:ci>T</ml:ci><ml:cn>1</ml:cn></ml:apply>
          </ml:lambda>
        </ml:declare>
      ML
    end
    let(:ast) { parse(declare) }

    it "reads the function name" do
      expect(ast.name).to eq("R")
    end

    it "reads the bound variables" do
      expect(ast.bound_variables).to eq(["T"])
    end

    it "marks a bvar reference as bound" do
      expect(ast.body.operands.first).to eq(node(:BoundVariable, name: "T"))
    end
  end

  describe "nested applies" do
    let(:nested) do
      <<~ML
        <ml:apply>
          <ml:power/>
          <ml:ci>T</ml:ci>
          <ml:apply><ml:plus/><ml:cn>1</ml:cn><ml:cn>1</ml:cn></ml:apply>
        </ml:apply>
      ML
    end
    let(:body) { parse(nested).body }

    it "parses the outer operator" do
      expect(body.operator).to eq(:**)
    end

    it "parses the inner operator" do
      expect(body.operands.last.operator).to eq(:+)
    end
  end

  it "parses constants" do
    pi = "<ml:apply><ml:times/><ml:pi/><ml:cn>2</ml:cn></ml:apply>"

    expect(parse(pi).body.operands.first).to eq(node(:Constant, name: :pi))
  end

  # MathML writes <degree> BEFORE the radicand and wraps it in an element.
  # We unwrap it and store operands as [value, degree].
  describe "roots" do
    let(:cube) do
      <<~ML
        <ml:apply>
          <ml:root/>
          <ml:degree><ml:cn>3</ml:cn></ml:degree>
          <ml:cn>27</ml:cn>
        </ml:apply>
      ML
    end

    let(:nested_degree) do
      <<~ML
        <ml:apply>
          <ml:root/>
          <ml:degree>
            <ml:apply><ml:plus/><ml:cn>1</ml:cn><ml:cn>2</ml:cn></ml:apply>
          </ml:degree>
          <ml:cn>27</ml:cn>
        </ml:apply>
      ML
    end

    it "parses a square root as a single operand" do
      body = parse("<ml:apply><ml:root/><ml:cn>9</ml:cn></ml:apply>").body

      expect(body).to eq(node(:Apply, operator: :root, operands: [num("9")]))
    end

    it "unwraps <degree> and puts the radicand first" do
      expect(parse(cube).body.operands).to eq([num("27"), num("3")])
    end

    it "allows a nested expression inside <degree>" do
      expect(parse(nested_degree).body.operands.last.operator).to eq(:+)
    end
  end

  # Cardinality: taking `.first` of several radicands or several degrees
  # would silently corrupt the evaluator's [value, degree] ordering.
  describe "malformed input" do
    let(:two_degrees) do
      <<~ML
        <ml:apply>
          <ml:root/>
          <ml:degree><ml:cn>2</ml:cn></ml:degree>
          <ml:degree><ml:cn>3</ml:cn></ml:degree>
          <ml:cn>8</ml:cn>
        </ml:apply>
      ML
    end

    let(:fat_degree) do
      <<~ML
        <ml:apply>
          <ml:root/>
          <ml:degree><ml:cn>2</ml:cn><ml:cn>3</ml:cn></ml:degree>
          <ml:cn>8</ml:cn>
        </ml:apply>
      ML
    end

    let(:two_radicands) do
      "<ml:apply><ml:root/><ml:cn>8</ml:cn><ml:cn>9</ml:cn></ml:apply>"
    end

    let(:no_radicand) do
      "<ml:apply><ml:root/><ml:degree><ml:cn>3</ml:cn></ml:degree></ml:apply>"
    end

    it "rejects an unsupported operator" do
      expect { parse("<ml:apply><ml:eq/><ml:cn>1</ml:cn></ml:apply>") }
        .to raise_error(Dcc::ExtractionError, /eq/)
    end

    it "rejects more than one radicand" do
      expect { parse(two_radicands) }
        .to raise_error(Dcc::ExtractionError, /exactly one radicand/i)
    end

    it "rejects a missing radicand" do
      expect { parse(no_radicand) }
        .to raise_error(Dcc::ExtractionError, /exactly one radicand/i)
    end

    it "rejects more than one <degree>" do
      expect { parse(two_degrees) }
        .to raise_error(Dcc::ExtractionError, /at most one/i)
    end

    it "rejects a <degree> holding several expressions" do
      expect { parse(fat_degree) }
        .to raise_error(Dcc::ExtractionError, /exactly one expression/i)
    end

    it "rejects an empty <degree>" do
      empty = "<ml:apply><ml:root/><ml:degree/><ml:cn>8</ml:cn></ml:apply>"

      expect { parse(empty) }
        .to raise_error(Dcc::ExtractionError, /exactly one expression/i)
    end

    # The parser is one of the two boundaries where a number enters.
    it "rejects a non-finite <cn>" do
      expect { parse("<ml:apply><ml:exp/><ml:cn>Infinity</ml:cn></ml:apply>") }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end

    it "rejects a <cn> that is not a number" do
      expect { parse("<ml:apply><ml:exp/><ml:cn>banana</ml:cn></ml:apply>") }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    it "rejects an operator given the wrong number of operands" do
      expect { parse("<ml:apply><ml:power/><ml:cn>3</ml:cn></ml:apply>") }
        .to raise_error(Dcc::ExtractionError, /takes 2\.\.2/)
    end

    it "rejects a math element holding no expression" do
      expect { parse("") }
        .to raise_error(Dcc::ExtractionError, /no formula/i)
    end
  end

  # A structured <cn> spreads its number across <sep/>-separated parts, and
  # concatenating them turns the rational one-half into 12. A plausible
  # wrong answer is worse than a refusal.
  describe "structured <cn>" do
    def cn(attrs, body)
      parse("<ml:apply><ml:abs/><ml:cn #{attrs}>#{body}</ml:cn></ml:apply>")
    end

    it "rejects a rational rather than reading 1<sep/>2 as twelve" do
      expect { cn('type="rational"', "1<ml:sep/>2") }
        .to raise_error(Dcc::ExtractionError, %r{<sep/>})
    end

    it "rejects e-notation" do
      expect { cn('type="e-notation"', "1<ml:sep/>3") }
        .to raise_error(Dcc::ExtractionError, %r{<sep/>})
    end

    it "rejects an unsupported type even without a separator" do
      expect { cn('type="hexdouble"', "FF") }
        .to raise_error(Dcc::ExtractionError, /Unsupported <cn> type/)
    end

    it "accepts a plain typed number" do
      expect(cn('type="real"', "1.5").body.operands.first).to eq(num("1.5"))
    end

    it "accepts an untyped number" do
      expect(cn("", "2").body.operands.first).to eq(num("2"))
    end

    # Same silent-wrong-number shape as <sep/>: octal 17 is fifteen, and
    # reading it as decimal seventeen is a plausible wrong answer.
    it "rejects an octal base rather than reading 17 as seventeen" do
      expect { cn('type="integer" base="8"', "17") }
        .to raise_error(Dcc::ExtractionError, /Unsupported <cn> base: 8/)
    end

    it "rejects a binary base" do
      expect { cn('base="2"', "101") }
        .to raise_error(Dcc::ExtractionError, /Unsupported <cn> base: 2/)
    end

    it "accepts an explicit base of ten" do
      expect(cn('base="10"', "17").body.operands.first).to eq(num("17"))
    end
  end
end
