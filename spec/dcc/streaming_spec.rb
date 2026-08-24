# frozen_string_literal: true

require "spec_helper"
require "json"
require "open3"
require "rbconfig"
require "stringio"

RSpec.describe Dcc::Streaming do
  def dcc_ns
    'xmlns:dcc="https://ptb.de/dcc"'
  end

  def doc(body, version: "3.3.0")
    si = 'xmlns:si="https://ptb.de/si"'
    %(<dcc:d #{dcc_ns} #{si} schemaVersion="#{version}">#{body}</dcc:d>)
  end

  def rooted(declarations, body)
    %(<r #{declarations} schemaVersion="3.3.0">#{body}</r>)
  end

  def stream_items(xml, **opts)
    found = []
    described_class.each_item(StringIO.new(xml), **opts) { |i| found << i }
    found
  end

  def stream_quantities(xml, **opts)
    found = []
    described_class.each_quantity(StringIO.new(xml), **opts) { |q| found << q }
    found
  end

  def item(id: "a", body: "<dcc:model>M</dcc:model>")
    %(<dcc:item id="#{id}">#{body}</dcc:item>)
  end

  def real(value: "1", unit: '\\metre')
    "<si:real><si:value>#{value}</si:value>" \
      "<si:unit>#{unit}</si:unit></si:real>"
  end

  def blob_quantity(payload)
    doc("<dcc:quantity>#{real}<dcc:influenceConditions>" \
        "<dcc:influenceCondition><dcc:name>" \
        '<dcc:content lang="en">t</dcc:content></dcc:name>' \
        "<dcc:data><dcc:xml>#{payload}</dcc:xml></dcc:data>" \
        "</dcc:influenceCondition></dcc:influenceConditions>" \
        "</dcc:quantity>")
  end

  def blob_raw(payload)
    quantity = stream_quantities(blob_quantity(payload)).first
    condition = quantity.influence_conditions.influence_condition.first
    condition.data.first.xml.first.raw.to_s
  end

  describe ".each_item" do
    let(:ptb) { load_fixture("dcc_examples", "example.xml") }

    it "yields every item in the PTB reference document" do
      expect(stream_items(ptb).map(&:id)).to eq(%w[dcc10g dcc100g])
    end

    it "auto-detects v2 from the fixture's schemaVersion" do
      expect(stream_items(ptb).first).to be_a(Dcc::V2::Item)
    end

    it "auto-detects v3 from a 3.x schemaVersion" do
      expect(stream_items(doc(item)).first).to be_a(Dcc::V3::Item)
    end

    it "honours an explicit version override" do
      streamed = stream_items(ptb, version: 3)
      expect(streamed.first).to be_a(Dcc::V3::Item)
    end

    it "parses the item body into the typed model" do
      expect(stream_items(doc(item)).first.model).to eq("M")
    end

    it "yields nothing for a valid document with no items" do
      expect(stream_items(doc("<dcc:other/>"))).to be_empty
    end

    it "returns an Enumerator when no block is given" do
      streamed = described_class.each_item(StringIO.new(doc(item)))
      expect(streamed).to be_a(Enumerator)
    end

    # The document is left unterminated, so reaching the end raises. Only a
    # reader that stops at the second yield gets through this.
    it "stops reading once the caller stops asking" do
      body = Array.new(50) { |i| item(id: "i#{i}") }.join
      truncated = %(<dcc:d #{dcc_ns} schemaVersion="3.3.0">#{body})
      streamed = described_class.each_item(StringIO.new(truncated))
      expect(streamed.first(2).map(&:id)).to eq(%w[i0 i1])
    end

    it "raises when that same document is consumed to the end" do
      body = Array.new(50) { |i| item(id: "i#{i}") }.join
      truncated = %(<dcc:d #{dcc_ns} schemaVersion="3.3.0">#{body})
      expect { stream_items(truncated) }.to raise_error(Dcc::ParseError)
    end
  end

  describe ".each_quantity" do
    let(:nested) do
      doc("<dcc:quantity id='outer'>#{real}<dcc:influenceConditions>" \
          "<dcc:influenceCondition><dcc:name>" \
          "<dcc:content lang='en'>t</dcc:content></dcc:name>" \
          "<dcc:data><dcc:quantity id='inner'>#{real(value: '20')}" \
          "</dcc:quantity></dcc:data>" \
          "</dcc:influenceCondition></dcc:influenceConditions>" \
          "</dcc:quantity>")
    end

    it "populates the D-SI quantity through the fallback context" do
      quantity = stream_quantities(doc("<dcc:quantity>#{real}" \
                                       "</dcc:quantity>")).first
      expect(quantity.real.map(&:unit)).to eq(['\\metre'])
    end

    it "yields only the outermost of a nested pair" do
      expect(stream_quantities(nested).map(&:id)).to eq(["outer"])
    end

    it "keeps the nested quantity reachable from the outer one" do
      outer = stream_quantities(nested).first
      inner = outer.influence_conditions.influence_condition.first
      expect(inner.data.first.quantity.first.id).to eq("inner")
    end
  end

  describe "opaque XML payloads" do
    it "preserves comments inside dcc:xml" do
      payload = '<f:b xmlns:f="urn:f"><!--KEEPME--><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("<!--KEEPME-->")
    end

    it "preserves processing instructions inside dcc:xml" do
      payload = '<f:b xmlns:f="urn:f"><?pi PIDATA?><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("<?pi PIDATA?>")
    end

    it "preserves a processing instruction with no data" do
      payload = '<f:b xmlns:f="urn:f"><?pi?><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("<?pi")
    end

    it "preserves an irregularly spaced processing instruction" do
      payload = '<f:b xmlns:f="urn:f"><?pi   a  b ?><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("a  b")
    end

    it "escapes markup characters in text" do
      payload = '<f:b xmlns:f="urn:f"><f:c>a &lt; b &amp; c</f:c></f:b>'
      expect(blob_raw(payload)).to include("a &lt; b &amp; c")
    end

    # SAX hands back an attribute value with every `&` still written as
    # `&#38;`, and hands back namespace URIs, comments and PI data untouched.
    # The reader has to decode one channel and leave the others alone, so
    # these pin each channel separately. Decoding one level lower, in the
    # shared attribute writer, passes the rows above and fails these.
    it "keeps an ampersand in a prefixed attribute on a descendant" do
      payload = '<f:b xmlns:f="urn:f" f:q="a&amp;b"><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include('f:q="a&amp;b"')
    end

    it "keeps an ampersand in a plain attribute on a descendant" do
      payload = '<f:b xmlns:f="urn:f"><f:c q="a&amp;b">v</f:c></f:b>'
      expect(blob_raw(payload)).to include('q="a&amp;b"')
    end

    it "keeps an ampersand in a namespace URI" do
      payload = '<f:b xmlns:f="http://f/?x=1&amp;y"><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include('xmlns:f="http://f/?x=1&amp;y"')
    end

    # The row that separates the correct fix from the plausible wrong one: a
    # namespace URI arrives decoded, so a literal `&#38;` in one is real text
    # and must survive. The plain-ampersand row above cannot catch this,
    # because it has no `&#38;` in it to corrupt.
    it "leaves a literal ampersand reference in a namespace URI alone" do
      payload = '<f:b xmlns:f="http://f/?x=1&amp;#38;y"><f:c>v</f:c></f:b>'
      expect(blob_raw(payload))
        .to include('xmlns:f="http://f/?x=1&amp;#38;y"')
    end

    it "leaves a literal ampersand reference in a comment alone" do
      payload = '<f:b xmlns:f="urn:f"><!--a&#38;b--><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("<!--a&#38;b-->")
    end

    it "leaves a literal ampersand reference in a PI alone" do
      payload = '<f:b xmlns:f="urn:f"><?pi a&#38;b?><f:c>v</f:c></f:b>'
      expect(blob_raw(payload)).to include("<?pi a&#38;b?>")
    end
  end

  describe "namespace resolution" do
    it "matches an element that rebinds its own prefix" do
      hit = %(<x:item xmlns:x="https://ptb.de/dcc" id="hit"/>)
      xml = rooted('xmlns:x="urn:root"', %(#{hit}<x:item id="miss"/>))
      expect(stream_items(xml).map(&:id)).to eq(["hit"])
    end

    it "restores the outer binding for a following sibling" do
      shadowed = %(<x:item id="a"><x:model xmlns:x="urn:other"/></x:item>)
      xml = rooted('xmlns:x="https://ptb.de/dcc"',
                   %(#{shadowed}<x:item id="b"/>))
      expect(stream_items(xml).map(&:id)).to eq(%w[a b])
    end

    it "matches the .xsd namespace alias older documents bind" do
      body = %(<dcc:item id="aliased"><dcc:model>M</dcc:model></dcc:item>)
      xml = rooted('xmlns:dcc="https://ptb.de/dcc.xsd"', body)
      expect(stream_items(xml).first.model).to eq("M")
    end

    it "matches items declared in a default namespace" do
      body = %(<item id="plain"><model>M</model></item>)
      xml = rooted('xmlns="https://ptb.de/dcc"', body)
      expect(stream_items(xml).first.model).to eq("M")
    end

    it "handles an undeclared default namespace on a descendant" do
      payload = '<f:b xmlns:f="urn:f"><c xmlns="">v</c></f:b>'
      expect(blob_raw(payload)).to include('xmlns=""')
    end
  end

  describe "custom model substitution" do
    before { stub_const("MyItem", Class.new(Dcc::V3::Item)) }

    after { Dcc::V3::Configuration.clear_custom_models }

    it "substitutes the root class, not just nested models" do
      Dcc::V3::Configuration.custom_models = { Dcc::V3::Item => MyItem }
      expect(stream_items(doc(item)).first).to be_a(MyItem)
    end
  end

  describe "version detection" do
    it "defaults to v3 when schemaVersion is absent" do
      xml = %(<dcc:d #{dcc_ns}>#{item}</dcc:d>)
      expect(stream_items(xml).first).to be_a(Dcc::V3::Item)
    end

    it "defaults to v3 when schemaVersion is malformed" do
      expect(stream_items(doc(item, version: "abc")).first)
        .to be_a(Dcc::V3::Item)
    end

    it "rejects an unsupported explicit version even with no matches" do
      expect { stream_items(doc("<dcc:other/>"), version: 5) }
        .to raise_error(Dcc::UnknownVersionError)
    end

    it "defaults to v3 for an unsupported major version" do
      expect(stream_items(doc(item, version: "9.0.0")).first)
        .to be_a(Dcc::V3::Item)
    end

    # `schemaVersion` sits on the DCC root, which is not always the document
    # root. Reading it off the outermost element instead pins every enveloped
    # certificate to v3.
    it "reads the version off a certificate nested in an envelope" do
      body = %(<env:Body>#{doc(item, version: '2.4.0')}</env:Body>)
      xml = %(<env:Envelope xmlns:env="urn:env">#{body}</env:Envelope>)
      expect(stream_items(xml).first).to be_a(Dcc::V2::Item)
    end

    it "defaults to v3 when the item is itself the document root" do
      xml = %(<dcc:item #{dcc_ns} id="a"><dcc:model>M</dcc:model></dcc:item>)
      expect(stream_items(xml).first).to be_a(Dcc::V3::Item)
    end

    # Anything inside a matched subtree is payload, not document structure —
    # an opaque `dcc:xml` blob could carry any attribute at all.
    it "ignores a schemaVersion on a descendant of a matched item" do
      model = %(<dcc:model schemaVersion="2.4.0">M</dcc:model>)
      xml = %(<dcc:d #{dcc_ns}>#{item(body: model)}</dcc:d>)
      expect(stream_items(xml).first).to be_a(Dcc::V3::Item)
    end

    # The first document with no `schemaVersion` above it falls back to v3,
    # and that has to stick: the model class and the context are memoised off
    # the version at the first yield.
    it "keeps the version settled once the first item is yielded",
       :aggregate_failures do
      later = %(<dcc:d schemaVersion="2.4.0">#{item(id: 'b')}</dcc:d>)
      streamed = stream_items(%(<r #{dcc_ns}>#{item}#{later}</r>))
      expect(streamed.map(&:id)).to eq(%w[a b])
      expect(streamed.map(&:class)).to eq([Dcc::V3::Item, Dcc::V3::Item])
    end

    # An envelope can carry a `schemaVersion` of its own. The certificate's
    # version has to win, not whichever attribute the parser happens to reach
    # first.
    it "ignores a schemaVersion on a non-DCC wrapper element",
       :aggregate_failures do
      meta = %(<e:meta schemaVersion="2.0.0"/>)
      xml = %(<e:env xmlns:e="urn:e">#{meta}#{doc(item)}</e:env>)
      streamed = stream_items(xml)
      expect(streamed.map(&:id)).to eq(["a"])
      expect(streamed.first).to be_a(Dcc::V3::Item)
    end
  end

  describe "equivalence with direct fragment parsing" do
    def direct(body)
      Dcc::V3::Item.from_xml(%(<dcc:item #{dcc_ns} #{body}), register: :dcc_v3)
    end

    def both(body)
      [direct(body), stream_items(doc(%(<dcc:item #{body}))).first]
    end

    # Every character class an attribute or a text node can carry, paired with
    # the literal it has to survive as. Parity alone would pass if both paths
    # corrupted a character the same way, so each row pins the literal too.
    #
    # This group used to cover only the classes that already round-tripped and
    # left out the ampersand — the one class that did not — which is how the
    # attribute double-escape reached main behind a green suite. Adding a class
    # here is cheaper than finding out this way again.
    character_classes = {
      "an escaped ampersand" => ["a&amp;b", "a&b"],
      "a decimal ampersand reference" => ["a&#38;b", "a&b"],
      "a hex ampersand reference" => ["a&#x26;b", "a&b"],
      "two ampersands in one value" => ["?a=1&amp;b=2&amp;c=3",
                                        "?a=1&b=2&c=3"],
      "a re-escaped decimal ampersand" => ["a&amp;#38;b", "a&#38;b"],
      "a re-escaped named ampersand" => ["a&amp;amp;b", "a&amp;b"],
      "a re-escaped hex ampersand" => ["a&amp;#x26;b", "a&#x26;b"],
      "a less-than" => ["a&lt;b", "a<b"],
      "a greater-than" => ["a&gt;b", "a>b"],
      "a double quote" => ["a&quot;b", %(a"b)],
      "an apostrophe" => ["a&apos;b", "a'b"],
      "a tab" => ["a&#x9;b", "a\tb"],
      "a newline" => ["a&#xA;b", "a\nb"],
      "a carriage return" => ["a&#xD;b", "a\rb"],
      "an astral character" => ["a\u{1F600}b", "a\u{1F600}b"],
      "a non-breaking space" => ["a b", "a b"],
    }

    character_classes.each do |description, (source, literal)|
      it "keeps #{description} in an attribute", :aggregate_failures do
        a, b = both(%(id="#{source}"><dcc:model>M</dcc:model></dcc:item>))
        expect(b.id).to eq(a.id)
        expect(b.id).to eq(literal)
      end

      it "keeps #{description} in a text node", :aggregate_failures do
        a, b = both(%(id="x"><dcc:model>#{source}</dcc:model></dcc:item>))
        expect(b.model).to eq(a.model)
        expect(b.model).to eq(literal)
      end
    end
  end

  describe "error handling" do
    it "raises ParseError on malformed XML" do
      expect { stream_items("<a><b>oops</a>") }
        .to raise_error(Dcc::ParseError)
    end

    it "raises ParseError on a truncated document" do
      expect { stream_items(%(<dcc:d #{dcc_ns}><dcc:item>)) }
        .to raise_error(Dcc::ParseError)
    end

    it "raises ParseError on empty input" do
      expect { stream_items("") }.to raise_error(Dcc::ParseError)
    end

    it "raises ParseError on whitespace-only input" do
      expect { stream_items("   \n  ") }.to raise_error(Dcc::ParseError)
    end

    it "lets an exception from the consumer block through untouched" do
      io = StringIO.new(doc(item))
      consumer = proc { raise Moxml::ParseError, "from the consumer" }
      expect { described_class.each_item(io, &consumer) }
        .to raise_error(Moxml::ParseError, /from the consumer/)
    end

    it "raises ParseError when the IO itself fails" do
      io = Class.new(StringIO) { def read(*) = raise(IOError, "boom") }
      expect { described_class.each_item(io.new("<a/>")) { |_| nil } }
        .to raise_error(Dcc::ParseError)
    end
  end

  describe "memory behaviour" do
    let(:probe) do
      lib = File.expand_path("../../lib", __dir__)
      out, err, status = Open3.capture3(RbConfig.ruby, "-I#{lib}",
                                        memory_probe_path)
      raise "probe failed: #{err}" unless status.success?

      JSON.parse(out)
    end

    # The counts are asserted non-zero first: a flat line at zero would
    # otherwise satisfy the equality and leave the gate blind.
    it "does not accumulate models, DOM nodes or fragment strings",
       :aggregate_failures do
      expect(probe["heap_growth_kb"]).to be < probe["budget_kb"]
      expect(probe["items_first"]).to be_positive
      expect(probe["elements_first"]).to be_positive
      expect(probe["items_last"]).to eq(probe["items_first"])
      expect(probe["elements_last"]).to eq(probe["elements_first"])
    end
  end

  # Runs in a child process so the suite's own loaded state and RSpec's
  # per-example retention cannot pollute the measurement.
  def memory_probe_path
    File.expand_path("../support/streaming_memory_probe.rb", __dir__)
  end
end
