# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "stringio"

RSpec.describe Dcc::Migrate do
  before { Dcc.load_all! }

  # The migration reports losses on stderr. Specs that assert on the migrated
  # document rather than the report keep the suite output readable.
  def silence_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original
  end

  let(:namespaces) do
    { "dcc" => "https://ptb.de/dcc", "si" => "https://ptb.de/si" }
  end

  let(:v3_dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  describe "version handling" do
    it "returns the same object untouched when from and to are equal" do
      expect(described_class.call(v3_dcc, from: "3.3.0", to: "3.3.0"))
        .to equal(v3_dcc)
    end

    it "rejects a target outside the bundled versions" do
      expect { described_class.call(v3_dcc, from: "3.3.0", to: "3.4.0-rc.2") }
        .to raise_error(Dcc::UnknownVersionError, /3\.4\.0-rc\.2/)
    end

    it "rejects an unknown target major" do
      expect { described_class.call(v3_dcc, from: "3.3.0", to: "9.9.9") }
        .to raise_error(Dcc::UnknownVersionError)
    end

    it "rejects a minor-version downgrade" do
      expect { described_class.call(v3_dcc, from: "3.3.0", to: "3.2.1") }
        .to raise_error(Dcc::UnsupportedMigrationError, /3\.3\.0.*3\.2\.1/)
    end

    it "rejects a major-version downgrade" do
      expect { described_class.call(v3_dcc, from: "3.3.0", to: "2.3.0") }
        .to raise_error(Dcc::UnsupportedMigrationError, /information/i)
    end

    it "warns before raising on a downgrade" do
      expect do
        described_class.call(v3_dcc, from: "3.3.0", to: "2.3.0")
      rescue Dcc::UnsupportedMigrationError
        nil
      end.to output(/downgrad/i).to_stderr
    end

    it "rewrites schemaVersion on a same-major upgrade" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      dcc.schema_version = "3.2.1"
      migrated = described_class.call(dcc, from: "3.2.1", to: "3.3.0")

      expect(migrated).not_to equal(dcc)
      expect(migrated.schema_version.to_s).to eq("3.3.0")
    end
  end

  describe Dcc::Migrate::Route do
    it "routes 2.3.0 to 3.3.0 through the V2ToV3 transform" do
      expect(described_class.for("2.3.0", "3.3.0")).to eq(Dcc::Migrate::V2ToV3)
    end

    it "needs no field transform for 3.2.1 to 3.3.0" do
      expect(described_class.for("3.2.1", "3.3.0")).to be_nil
    end

    it "does not know 2.1.0 to 3.3.0" do
      expect(described_class.supported?("2.1.0", "3.3.0")).to be(false)
    end

    # 12 versions, 132 ordered pairs, no prereleases — the whole space.
    it "registers only the pairs whose incompatibilities were verified" do
      pairs = Dcc::Schema::Version::DCC_ALL.permutation(2).select do |from, to|
        described_class.supported?(from, to)
      end

      expect(pairs).to contain_exactly(%w[2.3.0 3.3.0], %w[3.2.1 3.3.0])
    end
  end

  describe "unregistered pairs" do
    it "raises rather than silently no-opping on 2.1.0 to 3.3.0" do
      dcc = Dcc.parse(File.read(fixtures_path("dcc_examples", "example.xml")))
      expect { described_class.call(dcc, from: "2.1.0", to: "3.3.0") }
        .to raise_error(Dcc::UnsupportedMigrationError, /2\.1\.0.*3\.3\.0/)
    end

    # Every ordered pair that is not one of the two registered ones, in both
    # directions — 130 of the 132. Downgrades warn before raising, so the
    # whole loop runs inside a stderr capture to keep the output clean.
    it "raises for all 130 unregistered ordered pairs" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      pairs = Dcc::Schema::Version::DCC_ALL.permutation(2).reject do |from, to|
        Dcc::Migrate::Route.supported?(from, to)
      end
      expect(pairs.size).to eq(130)

      expect do
        pairs.each do |from, to|
          expect { described_class.call(dcc, from: from, to: to) }
            .to raise_error(Dcc::UnsupportedMigrationError),
                "expected #{from} -> #{to} to raise"
        end
      end.to output.to_stderr
    end
  end

  describe Dcc::Migrate::V2ToV3 do
    [
      %w[dcc_examples example.xml],
      %w[dcc_examples siliziumkugel.xml],
      %w[dcc_xsd example.xml],
      %w[dcc_xsd siliziumkugel.xml],
    ].each do |dir, file|
      it "produces XSD-valid v3 XML from #{dir}/#{file}" do
        migrated = described_class.call(
          File.read(fixtures_path(dir, file)), to: "3.3.0"
        )
        result = Dcc::Validate::Xsd.call(migrated, version: "3.3.0")

        expect(result.errors).to be_empty
        expect(result).to be_ok
      end
    end

    let(:source) { File.read(fixtures_path("dcc_examples", "example.xml")) }
    let(:migrated) { described_class.call(source, to: "3.3.0") }

    it "writes the target schemaVersion" do
      expect(migrated).to include('schemaVersion="3.3.0"')
    end

    it "upgrades every D-SI v1 expandedUnc to expandedMU" do
      expect(source.scan("<si:expandedUnc").size).to eq(10)
      expect(migrated).not_to include("<si:expandedUnc")
      expect(migrated.scan("<si:expandedMU").size).to eq(10)
      expect(migrated.scan("<si:valueExpandedMU").size).to eq(10)
    end

    it "keeps every quantity and D-SI real" do
      expect(migrated.scan(/<dcc:quantity[ >]/).size)
        .to eq(source.scan(/<dcc:quantity[ >]/).size)
      expect(migrated.scan(/<si:real[ >]/).size)
        .to eq(source.scan(/<si:real[ >]/).size)
    end

    # Checked structurally: a regex with `.*?` under /m runs past the closing
    # tag and matches an unrelated description later in the document.
    it "renames identification description to name" do
      doc = Nokogiri::XML(migrated)

      expect(doc.xpath("//dcc:identification/dcc:description", namespaces))
        .to be_empty
      expect(doc.xpath("//dcc:identification/dcc:name", namespaces).size)
        .to eq(6)
    end

    it "renames influenceCondition state to status" do
      expect(source).to include("<dcc:state>")
      expect(migrated).not_to include("<dcc:state>")
      expect(migrated).to include("<dcc:status>")
    end

    it "moves the metaData refId element onto the attribute" do
      expect(source).to match(%r{<dcc:metaData>.*?<dcc:refId>MRA</dcc:refId>}m)
      expect(migrated).to include('refId="MRA"')
      expect(migrated).not_to include("<dcc:refId>")
    end

    it "adds the mandatory performanceLocation" do
      expect(migrated)
        .to include("<dcc:performanceLocation>other</dcc:performanceLocation>")
    end

    it "adds the mandatory measurementResult name" do
      expect(source).not_to match(%r{<dcc:measurementResult>\s*<dcc:name>}m)
      expect(migrated).to match(%r{<dcc:measurementResult>\s*<dcc:name>}m)
    end

    it "merges the repeated usedMethod descriptions into one" do
      counts = migrated.scan(%r{<dcc:usedMethod>.*?</dcc:usedMethod>}m)
        .map { |block| block.scan("<dcc:description>").size }

      expect(counts.max).to eq(1)
    end

    it "is idempotent" do
      expect(described_class.call(migrated, to: "3.3.0")).to eq(migrated)
    end
  end

  describe "the coverage fixture" do
    let(:source) { File.read(fixtures_path("migrate", "v2_full_coverage.xml")) }
    let(:migrated) { Dcc::Migrate::V2ToV3.call(source, to: "3.3.0") }

    it "is valid v2.3.0 to begin with" do
      expect(Dcc::Validate::Xsd.call(source, version: "2.3.0").errors)
        .to be_empty
    end

    it "migrates to valid v3.3.0" do
      expect(Dcc::Validate::Xsd.call(migrated, version: "3.3.0").errors)
        .to be_empty
    end

    it "renames byteData data to dataBase64 under every byteDataType parent" do
      doc = Nokogiri::XML(migrated)

      expect(doc.xpath("//dcc:dataBase64", namespaces).size).to eq(2)
      expect(doc.xpath("//dcc:file/dcc:data", namespaces)).to be_empty
    end

    it "converts siunitx to latex" do
      expect(migrated).to include("<dcc:latex>")
      expect(migrated).not_to include("<dcc:siunitx>")
    end

    it "rehomes descriptionData as description/file" do
      doc = Nokogiri::XML(migrated)

      expect(doc.xpath("//dcc:descriptionData", namespaces)).to be_empty
      expect(doc.xpath("//dcc:description/dcc:file", namespaces).size).to eq(2)
    end

    it "strips whitespace from notEmptyString elements" do
      expect(source).to match(%r{<dcc:model>\s+\S})
      expect(migrated).to include("<dcc:model>Model X100</dcc:model>")
    end

    it "upgrades a coverageInterval outside any si:list" do
      expect(migrated).to include("<si:coverageIntervalMU>")
      expect(migrated).to include("<si:valueStandardMU>")
      expect(migrated).not_to include("<si:coverageInterval>")
    end

    it "normalizes a leading-dot coverage probability" do
      expect(source).to include("<si:coverageProbability>.95<")
      expect(migrated).to include("<si:coverageProbability>0.95<")
    end

    it "merges repeated descriptions under every narrowed parent" do
      doc = Nokogiri::XML(migrated)

      %w[software item measuringEquipment usedMethod].each do |parent|
        doc.xpath("//dcc:#{parent}", namespaces).each do |node|
          expect(node.xpath("dcc:description", namespaces).size).to eq(1),
                                                                    parent
        end
      end
    end

    it "reports the description ids lost to the merge" do
      expect { migrated }.to output(%r{description/@id=}).to_stderr
    end

    it "reports the trimmed whitespace" do
      expect { migrated }.to output(/whitespace trimmed/).to_stderr
    end

    it "reports the constructs v3 cannot represent" do
      expect { migrated }
        .to output(%r{formula/@lang.*calibrationLaboratory}m).to_stderr
    end

    it "is idempotent" do
      expect(Dcc::Migrate::V2ToV3.call(migrated, to: "3.3.0")).to eq(migrated)
    end

    context "when migrated through Dcc.migrate" do
      let(:result) do
        Dcc.migrate(Dcc.parse(source), from: "2.3.0", to: "3.3.0").to_xml
      end

      it "still validates against the v3.3.0 XSD" do
        expect(Dcc::Validate::Xsd.call(result, version: "3.3.0").errors)
          .to be_empty
      end

      it "keeps the upgraded non-list uncertainty" do
        expect(result).to include("<si:coverageIntervalMU>")
        expect(result).to include("<si:valueStandardMU>")
      end
    end
  end

  # Transform level only. `Dcc::Si::Base::SiList` has no mapping for a v1
  # `si:list`'s direct `si:real` children, so this document cannot survive
  # `Dcc.parse`. Asserting it through `Dcc.migrate` would fail for a reason
  # that has nothing to do with migration.
  describe "a v1-shaped si:list" do
    let(:source) { File.read(fixtures_path("migrate", "v2_si_list.xml")) }
    let(:migrated) { Dcc::Migrate::V2ToV3.call(source, to: "3.3.0") }

    it "is valid v2.3.0 to begin with" do
      expect(Dcc::Validate::Xsd.call(source, version: "2.3.0").errors)
        .to be_empty
    end

    it "migrates to valid v3.3.0" do
      expect(Dcc::Validate::Xsd.call(migrated, version: "3.3.0").errors)
        .to be_empty
    end

    it "renames the previousReport reference elements" do
      expect(migrated).to include("<dcc:referral>", "<dcc:referralID>")
      expect(migrated).not_to include("<dcc:reference>", "<dcc:referenceID>")
    end

    it "wraps the v1 list body in si:realList" do
      doc = Nokogiri::XML(migrated)

      expect(doc.xpath("//si:list/si:realList/si:real", namespaces).size)
        .to eq(2)
      expect(doc.xpath("//si:list/si:real", namespaces)).to be_empty
    end

    it "leaves list-local deprecated uncertainty alone" do
      list = migrated[%r{<si:list>.*?</si:list>}m]

      expect(list).to include("<si:expandedUnc>", "<si:coverageInterval>")
      expect(list).not_to include("<si:measurementUncertaintyUnivariate>")
    end

    it "is idempotent" do
      expect(Dcc::Migrate::V2ToV3.call(migrated, to: "3.3.0")).to eq(migrated)
    end
  end

  describe "version-specific element names" do
    it "keeps the v3 identification name through a round trip" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      identification =
        dcc.administrative_data.core_data.identifications.identification.first

      expect(identification.name.content.map(&:value).flatten)
        .to include("Order no.")
      expect(Nokogiri::XML(dcc.to_xml)
               .xpath("//dcc:identification/dcc:name", namespaces))
        .not_to be_empty
    end

    # example.xml carries its identifications under items and statements, not
    # coreData, so this asserts on the serialized shape rather than a path.
    it "keeps the v2 identification description through a round trip" do
      dcc = Dcc.parse(File.read(fixtures_path("dcc_examples", "example.xml")))
      doc = Nokogiri::XML(dcc.to_xml)

      expect(doc.xpath("//dcc:identification/dcc:description", namespaces).size)
        .to eq(6)
      expect(doc.xpath("//dcc:identification/dcc:name", namespaces)).to be_empty
    end

    it "keeps performanceLocation through a v3 round trip" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))

      expect(dcc.administrative_data.core_data.performance_location)
        .not_to be_nil
      expect(dcc.to_xml).to include("<dcc:performanceLocation>")
    end
  end

  describe "documents the migration must not silently break" do
    let(:source) { File.read(fixtures_path("migrate", "v2_full_coverage.xml")) }

    # A statement whose refId element points at the description the merge
    # removes. v2 allows this; leaving it alone emits a refId that resolves
    # to nothing.
    let(:with_reference) do
      statements = "    <dcc:statements>\n      " \
                   "<dcc:statement>\n        " \
                   "<dcc:norm>ISO 17025</dcc:norm>\n        " \
                   "<dcc:refId>item-desc-2</dcc:refId>\n      " \
                   "</dcc:statement>\n    " \
                   "</dcc:statements>\n  " \
                   "</dcc:administrativeData>"
      source.sub("  </dcc:administrativeData>") { statements }
    end

    let(:whitespace_only) do
      source.sub("<dcc:model>  Model X100  </dcc:model>") do
        "<dcc:model>   </dcc:model>"
      end
    end

    it "starts from valid v2 documents in both cases" do
      expect(Dcc::Validate::Xsd.call(with_reference, version: "2.3.0").errors)
        .to be_empty
      expect(Dcc::Validate::Xsd.call(whitespace_only, version: "2.3.0").errors)
        .to be_empty
    end

    it "repoints a reference to a merged-away description" do
      doc = Nokogiri::XML(
        Dcc::Migrate::V2ToV3.call(with_reference, to: "3.3.0"),
      )
      ids = doc.xpath("//*[@id]").map { |node| node["id"] }
      refs = doc.xpath("//*[@refId]").flat_map { |node| node["refId"].split }

      expect(refs).to include("item-desc-1")
      expect(refs - ids).to be_empty
    end

    it "reports the repointing" do
      expect { Dcc::Migrate::V2ToV3.call(with_reference, to: "3.3.0") }
        .to output(/repointed to item-desc-1/).to_stderr
    end

    it "still validates after repointing" do
      migrated = Dcc::Migrate::V2ToV3.call(with_reference, to: "3.3.0")

      expect(Dcc::Validate::Xsd.call(migrated, version: "3.3.0").errors)
        .to be_empty
    end

    it "refuses a value that trims to empty" do
      expect { Dcc::Migrate::V2ToV3.call(whitespace_only, to: "3.3.0") }
        .to raise_error(Dcc::UnsupportedMigrationError, /notEmptyStringType/)
    end
  end

  # v2.3.0 types THREE live elements `dcc:hashType` — certificate,
  # previousReport and linkedReport — and v3 renamed that type's
  # reference/referenceID children on all of them. A fourth `identifier`
  # appears in the file but sits inside the commented-out
  # metrologicallyTraceableType block, so no valid v2 document carries it.
  describe "hashType children on every parent carrying the type" do
    let(:hash_type_source) do
      doc = Nokogiri::XML(
        File.read(fixtures_path("migrate", "v2_full_coverage.xml")),
      )
      equipment = doc.at_xpath("//dcc:measuringEquipment", namespaces)
      # v2 measuringEquipmentType orders these name, equipmentClass,
      # description, descriptionData, certificate.
      equipment.at_xpath("dcc:name", namespaces)
        .add_next_sibling(Nokogiri::XML(<<~CLASS).root)
          <dcc:equipmentClass xmlns:dcc="https://ptb.de/dcc">
            <dcc:reference>DKD-R-6-1</dcc:reference>
            <dcc:classID>3.2</dcc:classID>
          </dcc:equipmentClass>
        CLASS
      # `previousReport` is the last child of coreData. The fixture omits it,
      # so without this the "every hashType parent" claim goes untested for
      # one of the three.
      doc.at_xpath("//dcc:coreData", namespaces)
        .add_child(Nokogiri::XML(<<~PREV).root)
          <dcc:previousReport xmlns:dcc="https://ptb.de/dcc">
            <dcc:reference><dcc:content lang="en">Prior</dcc:content></dcc:reference>
            <dcc:referenceID>PREV-1</dcc:referenceID>
            <dcc:procedure>SHA256</dcc:procedure><dcc:value>xyz</dcc:value>
          </dcc:previousReport>
        PREV
      # `statements` is the last child of administrativeData, and
      # statementMetaDataType also carries a `reference` v3 keeps as-is.
      doc.at_xpath("//dcc:administrativeData", namespaces)
        .add_child(Nokogiri::XML(<<~STMT).root)
          <dcc:statements xmlns:dcc="https://ptb.de/dcc">
            <dcc:statement><dcc:reference>ISO 17025</dcc:reference></dcc:statement>
          </dcc:statements>
        STMT
      anchor = equipment.at_xpath("dcc:descriptionData", namespaces) ||
        equipment.at_xpath("dcc:description", namespaces)
      anchor.add_next_sibling(Nokogiri::XML(<<~XML).root)
        <dcc:certificate xmlns:dcc="https://ptb.de/dcc">
          <dcc:reference><dcc:content lang="en">Cert doc</dcc:content></dcc:reference>
          <dcc:referenceID>CERT-1</dcc:referenceID>
          <dcc:procedure>SHA256</dcc:procedure>
          <dcc:value>abc123</dcc:value>
          <dcc:linkedReport>
            <dcc:reference><dcc:content lang="en">Linked</dcc:content></dcc:reference>
            <dcc:referenceID>LINK-1</dcc:referenceID>
            <dcc:procedure>SHA256</dcc:procedure>
            <dcc:value>def456</dcc:value>
          </dcc:linkedReport>
        </dcc:certificate>
      XML
      doc.to_xml
    end

    let(:hash_type_migrated) do
      silence_stderr { Dcc::Migrate::V2ToV3.call(hash_type_source, to: "3.3.0") }
    end

    it "starts from a valid v2.3.0 document" do
      expect(Dcc::Validate::Xsd.call(hash_type_source, version: "2.3.0").errors)
        .to be_empty
    end

    it "migrates a certificate to a valid v3 document" do
      errors = Dcc::Validate::Xsd
        .call(hash_type_migrated, version: "3.3.0").errors

      expect(errors).to be_empty
    end

    it "renames reference and referenceID under certificate" do
      certificate = Nokogiri::XML(hash_type_migrated)
        .at_xpath("//dcc:certificate", namespaces)

      expect(certificate.at_xpath("dcc:referral", namespaces).text)
        .to eq("Cert doc")
      expect(certificate.at_xpath("dcc:referralID", namespaces).text)
        .to eq("CERT-1")
    end

    it "renames reference and referenceID under previousReport" do
      previous = Nokogiri::XML(hash_type_migrated)
        .at_xpath("//dcc:previousReport", namespaces)

      expect(previous.at_xpath("dcc:referralID", namespaces).text)
        .to eq("PREV-1")
      expect(previous.at_xpath("dcc:reference", namespaces)).to be_nil
    end

    it "renames them inside a nested linkedReport" do
      linked = Nokogiri::XML(hash_type_migrated)
        .at_xpath("//dcc:certificate/dcc:linkedReport", namespaces)

      expect(linked.at_xpath("dcc:referralID", namespaces).text).to eq("LINK-1")
      expect(linked.at_xpath("dcc:reference", namespaces)).to be_nil
    end

    # Spelled out rather than iterating HASH_TYPE_PARENTS: a spec driven by
    # the constant it is testing cannot catch that constant losing an entry.
    it "leaves no v2 reference or referenceID under any hashType parent" do
      doc = Nokogiri::XML(hash_type_migrated)

      %w[previousReport certificate linkedReport].each do |parent|
        expect(doc.xpath("//dcc:#{parent}/dcc:reference", namespaces))
          .to be_empty
        expect(doc.xpath("//dcc:#{parent}/dcc:referenceID", namespaces))
          .to be_empty
      end
    end

    it "covers exactly the three v2 elements typed dcc:hashType" do
      expect(Dcc::Migrate::V2ToV3::HASH_TYPE_PARENTS)
        .to contain_exactly("previousReport", "certificate", "linkedReport")
    end

    # v3 keeps equipmentClass/reference and statement/reference named
    # `reference`, so the rename must stay anchored on the hashType parents.
    it "does not rename reference under equipmentClass or statement" do
      doc = Nokogiri::XML(hash_type_migrated)

      %w[equipmentClass statement].each do |parent|
        expect(doc.xpath("//dcc:#{parent}/dcc:reference", namespaces))
          .not_to(be_empty, "expected #{parent}/reference to survive")
        expect(doc.xpath("//dcc:#{parent}/dcc:referral", namespaces))
          .to be_empty
      end
    end
  end

  # `Dcc.migrate` transforms the source XML, so a construct the v2 model
  # cannot round-trip still reaches the transform. descriptionData is the
  # worked case: the v2 model drops it, and the transform rewrites it to
  # description/file, which the v3 model does preserve.
  describe "migrating source XML rather than a re-serialized model" do
    let(:coverage_xml) do
      File.read(fixtures_path("migrate", "v2_full_coverage.xml"))
    end

    def attachment_census(xml)
      doc = Nokogiri::XML(xml)
      {
        file: doc.xpath("//dcc:description/dcc:file", namespaces).size,
        data: doc.xpath("//dcc:dataBase64", namespaces).size,
      }
    end

    it "carries descriptionData attachments through to the returned model" do
      migrated = silence_stderr do
        Dcc.migrate(coverage_xml, from: "2.3.0", to: "3.3.0")
      end

      expect(attachment_census(migrated.to_xml)).to eq(file: 2, data: 2)
    end

    it "loses them when handed a parsed model instead" do
      migrated = silence_stderr do
        Dcc.migrate(Dcc.parse(coverage_xml), from: "2.3.0", to: "3.3.0")
      end

      expect(attachment_census(migrated.to_xml)).to eq(file: 0, data: 0)
    end

    it "reports every loss on the source-XML path" do
      expect { Dcc.migrate(coverage_xml, from: "2.3.0", to: "3.3.0") }
        .to output(include("discarded 7 construct")).to_stderr
    end

    it "always returns a parsed model, never the source string" do
      migrated = silence_stderr do
        Dcc.migrate(coverage_xml, from: "2.3.0", to: "2.3.0")
      end

      expect(migrated).to be_a(Dcc::V2::DigitalCalibrationCertificate)
    end
  end

  describe "input validation" do
    it "rejects nil" do
      expect { Dcc.migrate(nil, from: "2.3.0", to: "3.3.0") }
        .to raise_error(Dcc::Error, /expects DCC source XML or a parsed DCC/)
    end

    it "rejects a type that is neither source XML nor a parsed DCC" do
      expect { Dcc.migrate(42, from: "2.3.0", to: "3.3.0") }
        .to raise_error(Dcc::Error, /got Integer/)
    end

    it "accepts source XML as a string" do
      xml = File.read(fixtures_path("migrate", "v2_full_coverage.xml"))
      migrated = silence_stderr { Dcc.migrate(xml, from: "2.3.0", to: "3.3.0") }

      expect(migrated).to be_a(Dcc::V3::DigitalCalibrationCertificate)
      expect(migrated.schema_version.to_s).to eq("3.3.0")
    end

    it "accepts source XML as an IO" do
      io = StringIO.new(
        File.read(fixtures_path("migrate", "v2_full_coverage.xml")),
      )
      migrated = silence_stderr { Dcc.migrate(io, from: "2.3.0", to: "3.3.0") }

      expect(migrated).to be_a(Dcc::V3::DigitalCalibrationCertificate)
    end

    it "rejects XML with no root element" do
      expect { Dcc::Migrate::V2ToV3.call("", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /well-formed|no root element/)
    end

    # Strict parsing: recovery mode would drop everything after the first
    # syntax error and migrate the fragment, reporting no loss for the
    # sections it never saw.
    it "rejects truncated XML instead of migrating the fragment" do
      xml = File.read(fixtures_path("migrate", "v2_full_coverage.xml"))
      truncated = xml[0, xml.index("<dcc:measurementResults")]

      expect { Dcc.migrate(truncated, from: "2.3.0", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /well-formed/)
    end

    # Every xpath rule binds `dcc:` to the canonical URI, so an alias-namespace
    # document would match nothing and come back unmigrated but stamped v3.
    it "rejects the dcc.xsd alias namespace rather than silently skipping" do
      xml = File.read(fixtures_path("migrate", "v2_full_coverage.xml"))
        .sub('xmlns:dcc="https://ptb.de/dcc"',
             'xmlns:dcc="https://ptb.de/dcc.xsd"')

      expect { Dcc.migrate(xml, from: "2.3.0", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /namespace/)
    end

    # Accepting raw XML must not accept just any well-formed XML: the target
    # parser builds an empty certificate from a foreign root rather than
    # refusing it, so a stray document would migrate to a valid-looking blank.
    it "rejects well-formed XML that is not a DCC" do
      expect { Dcc.migrate("<xml/>", from: "2.3.0", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /digitalCalibrationCertificate/)
    end

    # The schemaVersion-only and same-version routes never reach a transform,
    # so the DCC-root check cannot live inside one.
    it "rejects a foreign root on every route, not just the transform" do
      [%w[2.3.0 3.3.0], %w[3.2.1 3.3.0], %w[3.3.0 3.3.0]].each do |from, to|
        expect { Dcc.migrate("<xml/>", from: from, to: to) }
          .to raise_error(Dcc::ParseError, /digitalCalibrationCertificate/),
              "expected #{from} -> #{to} to reject a foreign root"
      end
    end

    # Any Serializable serialises happily, so the root check has to cover the
    # model path too or a non-DCC model migrates into an empty certificate.
    it "rejects a parsed model that is not a DCC document" do
      expect { Dcc.migrate(Dcc::V3::Formula.new, from: "3.2.1", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /digitalCalibrationCertificate/)
    end

    # The same-version no-op returns its input, so it needs the same check or
    # it becomes the one path that hands back a non-DCC object.
    it "rejects a non-DCC model on the same-version path too" do
      expect { Dcc.migrate(Dcc::V3::Formula.new, from: "3.3.0", to: "3.3.0") }
        .to raise_error(Dcc::ParseError, /digitalCalibrationCertificate/)
    end

    it "rejects a DCC root in the wrong namespace" do
      expect do
        Dcc.migrate(
          '<digitalCalibrationCertificate xmlns="https://example.com/x"/>',
          from: "2.3.0", to: "3.3.0",
        )
      end.to raise_error(Dcc::ParseError, /namespace/)
    end
  end

  describe "end to end through Dcc.migrate" do
    let(:source) { File.read(fixtures_path("dcc_examples", "example.xml")) }
    let(:result) do
      Dcc.migrate(Dcc.parse(source), from: "2.3.0", to: "3.3.0").to_xml
    end

    def count(xml, tag)
      xml.scan(/<#{tag}[ >]/).size
    end

    it "carries the uncertainty upgrade all the way to the output" do
      expect(count(source, "si:expandedUnc")).to eq(10)
      expect(count(result, "si:expandedUnc")).to eq(0)
      expect(count(result, "si:expandedMU")).to eq(10)
      expect(count(result, "si:valueExpandedMU")).to eq(10)
    end

    it "loses no quantity, list or D-SI real" do
      %w[dcc:quantity dcc:list si:real].each do |tag|
        expect(count(result, tag)).to eq(count(source, tag)),
                                      "#{tag}: #{count(source, tag)} in, " \
                                      "#{count(result, tag)} out"
      end
    end

    # example.xml is valid v2.3.0, but a plain parse-and-serialize round trip
    # already fails v2.3.0 with 8 "quantity missing child" errors: the model
    # types `noQuantity` as :string where the XSD says textType, so all 8 are
    # dropped before migration runs. Requiring the migrated output to be clean
    # would require the migration to repair a parse loss. What it must
    # guarantee is that it adds nothing new — asserted here. Absolute XSD
    # validity through the public API is covered by the coverage fixture.
    it "introduces no XSD errors beyond the pre-existing parse loss" do
      before = Dcc::Validate::Xsd
        .call(Dcc.parse(source).to_xml, version: "2.3.0").errors
      after = Dcc::Validate::Xsd.call(result, version: "3.3.0").errors

      expect(before.size).to eq(8)
      expect(after.size).to eq(before.size)
      expect(after.map(&:message))
        .to all(include("quantity", "Missing child element"))
    end

    it "carries the renamed identification name and condition status" do
      doc = Nokogiri::XML(result)

      expect(doc.xpath("//dcc:identification/dcc:name", namespaces).size)
        .to eq(6)
      expect(result).to include("<dcc:status>")
      expect(result).to include("<dcc:performanceLocation>")
    end
  end
end
