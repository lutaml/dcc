# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Builder do
  before { Dcc.load_all! }

  describe ".call" do
    it "builds a minimal DCC from the DSL" do
      dcc = described_class.call(version: 3) do
        administrative_data do
          core_data do
            unique_identifier "urn:uuid:test-123"
            country_code "DE"
            used_lang "en"
            mandatory_lang "en"
          end
          items { item(model: "Test") }
        end
      end

      expect(dcc).to be_a(::Dcc::V3::DigitalCalibrationCertificate)
      expect(dcc.administrative_data.core_data.unique_identifier).to eq("urn:uuid:test-123")
      expect(dcc.administrative_data.core_data.country_code_iso_3166_1.to_s).to eq("DE")
      expect(dcc.administrative_data.core_data.used_lang_code_iso_639_1).to include("en")
      expect(dcc.administrative_data.items.item.size).to eq(1)
    end

    it "raises BuilderError when core_data is missing" do
      expect do
        described_class.call do
          administrative_data { items { item(model: "X") } }
        end
      end.to raise_error(::Dcc::BuilderError, /core_data is required/)
    end

    it "raises BuilderError when items is missing" do
      expect do
        described_class.call do
          administrative_data do
            core_data do
              unique_identifier "x"
              country_code "DE"
              used_lang "en"
              mandatory_lang "en"
            end
          end
        end
      end.to raise_error(::Dcc::BuilderError, /items is required/)
    end
  end
end