# frozen_string_literal: true

require "spec_helper"
require "digest"

RSpec.describe Dcc::Server::Storage::Memory do
  let(:xml) { "<digitalCalibrationCertificate/>" }

  it "stores and retrieves by SHA-256 id" do
    entry = subject.put(xml)
    expect(entry.id).to eq(::Digest::SHA256.hexdigest(xml))
    fetched = subject.get(entry.id)
    expect(fetched.xml).to eq(xml)
  end

  it "returns nil for unknown id" do
    expect(subject.get("nonexistent")).to be_nil
  end

  it "deletes by id" do
    entry = subject.put(xml)
    expect(subject.delete(entry.id)).to be(true)
    expect(subject.get(entry.id)).to be_nil
  end

  it "supports size and clear" do
    subject.put(xml)
    expect(subject.size).to eq(1)
    subject.clear
    expect(subject.size).to eq(0)
  end
end

RSpec.describe Dcc::Server do
  describe ".available?" do
    it "reflects whether sinatra is installed" do
      expect([true, false]).to include(described_class.available?)
    end
  end

  describe ".ensure_available!" do
    it "does not raise when sinatra is available" do
      skip "sinatra not available in this bundle" unless described_class.available?

      expect { described_class.ensure_available! }.not_to raise_error
    end
  end
end