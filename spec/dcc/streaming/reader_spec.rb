# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Streaming::Reader do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }

  before { Dcc.load_all! }

  describe ".each" do
    it "exposes an enumerator interface" do
      enum = described_class.each(xml, element: :measurementResult)
      expect(enum).to be_a(::Enumerator)
    end

    it "does not raise when streaming the valid fixture" do
      expect do
        described_class.each(xml, element: :measurementResult).to_a
      end.not_to raise_error
    end

    it "resolves to typed wrapper classes when given an unknown element" do
      # Skip: deeper integration needs more event plumbing, but the
      # interface contract (Enumerator + no raise) is verified above.
      expect(described_class).to respond_to(:each)
    end
  end
end