# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::Schematron do
  let(:valid_xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:invalid_xml) do
    File.read(fixtures_path("dcclib", "invalid_schematron.xml"))
  end

  before { Dcc::V3.load_all! }

  describe ".call" do
    it "accepts a valid document" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      expect(result.source).to eq("schematron")
      expect(result.schema_version).to eq("3.3.0")
      expect(result.errors).to be_empty
    end

    it "returns a Result model with to_s/to_json/to_yaml" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      expect(result).to respond_to(:to_s)
      expect(result).to respond_to(:to_json)
      expect(result).to respond_to(:to_yaml)
    end

    it "runs every rule without crashing on either fixture" do
      [valid_xml, invalid_xml].each do |xml|
        dcc = Dcc.parse(xml)
        expect { described_class.call(dcc) }.not_to raise_error
      end
    end

    it "returns codes for any issues it finds" do
      dcc = Dcc.parse(valid_xml)
      result = described_class.call(dcc)
      result.errors.each do |e|
        expect(e.code).to match(/\Adcc\.schematron\./)
      end
    end
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::DateRangeCheck do
  let(:dcc) do
    Dcc.parse(File.read(fixtures_path("dcclib", "invalid_schematron.xml")))
  end

  before { Dcc::V3.load_all! }

  it "validates without crashing" do
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::IsoCodeValidation do
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  before { Dcc::V3.load_all! }

  it "passes valid ISO codes" do
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_empty
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::LanguageCodeDedup do
  before { Dcc::V3.load_all! }

  it "passes for valid documents" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

# A plugin-supplied rule. Fires on any document carrying a schemaVersion,
# so it is guaranteed to trigger on the valid.xml fixture.
class PluginProbeRule < Dcc::Validate::Schematron::Rules::Base
  def check_on(dcc)
    return [] unless Dcc::TypeGuards.has_attribute?(dcc, :schema_version)

    [issue(severity: :error, message: "plugin rule fired")]
  end
end

RSpec.describe Dcc::Validate::Schematron::Profile do
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  before do
    Dcc::V3.load_all!
    Dcc::Plugin.reset!
  end

  after { Dcc::Plugin.reset! }

  it "keeps the built-in rules" do
    expect(described_class.new(dcc).rules)
      .to include(Dcc::Validate::Schematron::Rules::DateRangeCheck)
  end

  it "freezes the rule list it exposes" do
    expect(described_class.new(dcc).rules).to be_frozen
  end

  it "omits plugin rules that were never registered" do
    expect(described_class.new(dcc).rules).not_to include(PluginProbeRule)
  end

  it "appends a registered plugin validator" do
    Dcc::Plugin.register(:validators, PluginProbeRule)
    expect(described_class.new(dcc).rules).to include(PluginProbeRule)
  end

  it "fires a plugin rule during a real Schematron run" do
    Dcc::Plugin.register(:validators, PluginProbeRule)
    result = Dcc::Validate::Schematron.call(dcc)
    expect(result.issues.map(&:code))
      .to include("dcc.schematron.plugin_probe_rule")
  end

  it "reports no plugin code when nothing is registered" do
    result = Dcc::Validate::Schematron.call(dcc)
    expect(result.issues.map(&:code))
      .not_to include("dcc.schematron.plugin_probe_rule")
  end
end

# Broken plugin rules for the fault-isolation specs below. Rules that also
# fire a healthy issue would blur the assertion that the built-in findings
# survive, so each broken rule does only one bad thing. Defined at the top
# level, not inside a block, so no constant leaks out of an example group.
class RaisingPluginRule < Dcc::Validate::Schematron::Rules::Base
  def check_on(_dcc)
    raise "plugin exploded"
  end
end

class RequiredArgPluginRule < Dcc::Validate::Schematron::Rules::Base
  def initialize(required)
    @required = required
    super()
  end

  def check_on(_dcc)
    []
  end
end

class NilReturningPluginRule < Dcc::Validate::Schematron::Rules::Base
  def check_on(_dcc)
    nil
  end
end

# A broken plugin rule is third-party code: its failure must be contained
# and attributed, never allowed to abort the run and lose the built-in
# rules' findings.
RSpec.describe Dcc::Validate::Schematron::Profile, "#call" do
  # The invalid fixture, so the built-in rules have real findings to lose.
  let(:dcc) do
    Dcc.parse(File.read(fixtures_path("dcclib", "invalid_schematron.xml")))
  end

  before do
    Dcc::V3.load_all!
    Dcc::Plugin.reset!
  end

  after { Dcc::Plugin.reset! }

  shared_examples "a contained plugin failure" do |rule_class|
    before { Dcc::Plugin.register(:validators, rule_class) }

    it "does not abort the run" do
      expect { Dcc::Validate::Schematron.call(dcc) }.not_to raise_error
    end

    it "reports exactly one error issue naming the rule class" do
      failures = Dcc::Validate::Schematron.call(dcc).issues
        .select { |i| i.code == "dcc.schematron.plugin_failure" }
      expect(failures.size).to eq(1)
      expect(failures.first.severity).to eq(:error)
      expect(failures.first.message).to include(rule_class.name)
    end

    it "keeps the issues the built-in rules found" do
      broken = Dcc::Validate::Schematron.call(dcc).issues.map(&:code)
      Dcc::Plugin.reset!
      baseline = Dcc::Validate::Schematron.call(dcc).issues.map(&:code)
      expect(baseline).not_to be_empty
      expect(broken).to include(*baseline)
    end
  end

  context "with a plugin rule whose check_on raises" do
    it_behaves_like "a contained plugin failure", RaisingPluginRule
  end

  context "with a plugin rule whose initialize takes a required argument" do
    it_behaves_like "a contained plugin failure", RequiredArgPluginRule
  end

  context "with a plugin rule whose check_on returns nil" do
    it_behaves_like "a contained plugin failure", NilReturningPluginRule
  end

  it "still fails fast when a built-in rule raises" do
    allow(Dcc::Validate::Schematron::Rules::DateRangeCheck)
      .to receive(:new).and_raise("built-in bug")
    expect { Dcc::Validate::Schematron.call(dcc) }
      .to raise_error("built-in bug")
  end
end

# `register_validator` accepts any class defining `#check_on`, anonymous ones
# included, and `Rule#code` derives its code from the class name. An anonymous
# class has no name, so a rule built this way used to raise from inside the run.
RSpec.describe Dcc::Validate::Schematron::Rule do
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  # Held in a `let`, never assigned to a constant — assigning `Class.new` to a
  # constant names the class and hides the very case under test.
  let(:anonymous_rule) do
    Class.new(Dcc::Validate::Schematron::Rules::Base) do
      def check_on(_dcc)
        [issue(severity: :error, message: "anonymous rule fired")]
      end
    end
  end

  before do
    Dcc::V3.load_all!
    Dcc::Plugin.reset!
  end

  after { Dcc::Plugin.reset! }

  it "has no class name to derive a code from" do
    expect(anonymous_rule.name).to be_nil
  end

  it "codes an anonymous rule without raising" do
    expect(anonymous_rule.new.code).to eq("dcc.schematron.anonymous")
  end

  it "still derives a named rule's code from its class name" do
    expect(Dcc::Validate::Schematron::Rules::DateRangeCheck.new.code)
      .to eq("dcc.schematron.date_range_check")
  end

  context "when registered as a plugin validator" do
    before { Dcc::Plugin.register(:validators, anonymous_rule) }

    it "completes the run instead of raising" do
      expect { Dcc::Validate::Schematron.call(dcc) }.not_to raise_error
    end

    it "emits the anonymous rule's issue" do
      expect(Dcc::Validate::Schematron.call(dcc).issues.map(&:code))
        .to include("dcc.schematron.anonymous")
    end

    # The point of coding rather than raising: one anonymous plugin rule must
    # not cost the caller every issue the built-in rules already found.
    it "keeps the issues the built-in rules found" do
      expect(Dcc::Validate::Schematron.call(dcc).issues.map(&:code))
        .to include("dcc.schematron.used_software_placement")
    end
  end
end
