# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Namespace do
  describe "Dcc::Namespace::Dcc" do
    it "uses https://ptb.de/dcc as the canonical URI" do
      expect(Dcc::Namespace::Dcc.uri).to eq("https://ptb.de/dcc")
    end

    it "accepts the legacy alias URI" do
      expect(Dcc::Namespace::Dcc.uri_aliases).to include("https://ptb.de/dcc.xsd")
    end

    it "uses 'dcc' as the default prefix" do
      expect(Dcc::Namespace::Dcc.prefix_default).to eq("dcc")
    end

    it "imports Si, MathMl, and Dsig" do
      imported = Dcc::Namespace::Dcc.imports
      expect(imported).to include(Dcc::Namespace::Si)
      expect(imported).to include(Dcc::Namespace::MathMl)
      expect(imported).to include(Dcc::Namespace::Dsig)
    end
  end

  describe "Dcc::Namespace::Si" do
    it "uses https://ptb.de/si" do
      expect(Dcc::Namespace::Si.uri).to eq("https://ptb.de/si")
    end

    it "uses 'si' as the prefix" do
      expect(Dcc::Namespace::Si.prefix_default).to eq("si")
    end

    it "imports Qudt" do
      expect(Dcc::Namespace::Si.imports).to include(Dcc::Namespace::Qudt)
    end
  end

  describe "Dcc::Namespace::MathMl" do
    it "uses the W3C MathML URI" do
      expect(Dcc::Namespace::MathMl.uri).to eq("http://www.w3.org/1998/Math/MathML")
    end

    it "uses 'ml' as the prefix" do
      expect(Dcc::Namespace::MathMl.prefix_default).to eq("ml")
    end
  end

  describe "Dcc::Namespace::Dsig" do
    it "uses the W3C XMLDSig URI" do
      expect(Dcc::Namespace::Dsig.uri).to eq("http://www.w3.org/2000/09/xmldsig#")
    end

    it "uses 'ds' as the prefix" do
      expect(Dcc::Namespace::Dsig.prefix_default).to eq("ds")
    end
  end

  describe "Dcc::Namespace::Qudt" do
    it "uses the QUDT vocabulary URI" do
      expect(Dcc::Namespace::Qudt.uri).to eq("http://qudt.org/vocab/")
    end
  end
end
