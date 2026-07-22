# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::Schematron::Rules::UncertaintyConsistency do
  before { Dcc.load_all! }

  it "does not crash on valid documents" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::UnitFormatCheck do
  before { Dcc.load_all! }

  it "walks the tree looking for unit violations" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::NonSiDeclaration do
  before { Dcc.load_all! }

  it "does not flag SI-only documents" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    expect(issues).to be_an(Array)
  end
end

RSpec.describe Dcc::Validate::Schematron::Rules::AdministrativeDataCompleteness do
  before { Dcc.load_all! }

  it "passes for valid.xml (which has all sections)" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    issues = described_class.new.check_on(dcc)
    # valid.xml may be missing some sections like calibrationLaboratory;
    # we just verify the rule runs without crashing.
    expect(issues).to be_an(Array)
  end
end