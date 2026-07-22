# frozen_string_literal: true

require "spec_helper"

class SamplePlugin
  def name; "sample"; end
end

RSpec.describe Dcc::Plugin do
  before { described_class.reset! }

  describe ".register and .all" do
    it "stores plugins by category" do
      described_class.register(:validators, SamplePlugin)
      expect(described_class.all(:validators)).to include(SamplePlugin)
    end

    it "isolates categories" do
      described_class.register(:validators, SamplePlugin)
      expect(described_class.all(:converters)).to be_empty
    end

    it "supports any? check" do
      expect(described_class.any?(:validators)).to be(false)
      described_class.register(:validators, SamplePlugin)
      expect(described_class.any?(:validators)).to be(true)
    end

    it "returns a copy of the registry (mutation safety)" do
      described_class.register(:validators, SamplePlugin)
      list = described_class.all(:validators)
      list.clear
      expect(described_class.all(:validators)).to include(SamplePlugin)
    end
  end

  describe ".categories" do
    it "lists categories in use" do
      described_class.register(:validators, SamplePlugin)
      described_class.register(:converters, SamplePlugin)
      expect(Dcc::Plugin::Registry.categories).to include(:validators, :converters)
    end
  end
end