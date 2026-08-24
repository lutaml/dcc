# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Diff do
  before { Dcc::Si::V2.load_all! }

  def real_list(values)
    Dcc::Si::V2::RealListXmlList.from_xml(<<~XML)
      <si:realListXMLList xmlns:si="https://ptb.de/si">
        <si:valueXMLList>#{values}</si:valueXMLList>
        <si:unitXMLList>\\kelvin</si:unitXMLList>
      </si:realListXMLList>
    XML
  end

  # D-SI writes `NaN` for a not-measured entry, and IEEE says NaN is not equal
  # to NaN. `Values#==` honours that on purpose, so the diff has to answer the
  # document question — did this change? — rather than the numeric one.
  describe "a document compared against an identical copy" do
    it "reports no change when the list carries NaN" do
      changes = described_class.call(real_list("1.5 NaN 2.5"),
                                     real_list("1.5 NaN 2.5")).changes
      expect(changes).to be_empty
    end

    it "reports no change when the list is all finite" do
      changes = described_class.call(real_list("1.5 2.0 2.5"),
                                     real_list("1.5 2.0 2.5")).changes
      expect(changes).to be_empty
    end
  end

  # The NaN handling must not make the diff blind: a list that really did
  # change still has to be reported, NaN or not.
  describe "a document compared against a different one" do
    it "reports a change when a finite value differs" do
      changes = described_class.call(real_list("1.5 2.0 2.5"),
                                     real_list("1.5 9.9 2.5")).changes
      expect(changes.size).to eq(1)
    end

    it "reports a change when NaN replaces a measured value" do
      changes = described_class.call(real_list("1.5 2.0 2.5"),
                                     real_list("1.5 NaN 2.5")).changes
      expect(changes.size).to eq(1)
    end

    it "reports a change when a measured value replaces NaN" do
      changes = described_class.call(real_list("1.5 NaN 2.5"),
                                     real_list("1.5 2.0 2.5")).changes
      expect(changes.size).to eq(1)
    end

    it "reports a change when the lists are different lengths" do
      changes = described_class.call(real_list("1.5 NaN"),
                                     real_list("1.5 NaN 2.5")).changes
      expect(changes.size).to eq(1)
    end
  end

  # `Values.new` takes whatever it is handed, so a list built in Ruby rather
  # than parsed can hold entries that were never BigDecimals. Asking one of
  # those whether it is NaN raises.
  describe "a list assigned in Ruby rather than parsed" do
    let(:values) { Dcc::Type::DecimalXmlList::Values }

    it "reports a change between unequal non-decimal entries" do
      changes = described_class.call(values.new(["1"]),
                                     values.new(["2"])).changes
      expect(changes.size).to eq(1)
    end

    it "reports no change between equal non-decimal entries" do
      changes = described_class.call(values.new(["1"]),
                                     values.new(["1"])).changes
      expect(changes).to be_empty
    end
  end
end
