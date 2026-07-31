# frozen_string_literal: true

require "nokogiri"

module Dcc
  module Migrate
    # Rewrites a DCC v2.x document into the v3.x wire format.
    #
    # v3 renamed several elements, made `coreData/performanceLocation` and
    # `measurementResult/name` mandatory, moved the statement `refId` from a
    # child element to an attribute, narrowed four `description` elements to
    # single occurrence, tightened many string types to reject surrounding
    # whitespace, and switched from D-SI v1 to D-SI v2.
    #
    # Two v2 constructs have no v3 home — `formula/@lang` and the second and
    # later `calibrationLaboratory/contact`. Those, the element ids lost to a
    # description merge, and every trimmed value are reported rather than
    # dropped in silence.
    #
    # Every rule is conditional, so applying the transform twice is a no-op.
    module V2ToV3
      NS = {
        "dcc" => "https://ptb.de/dcc",
        "si" => "https://ptb.de/si",
      }.freeze

      # `performanceLocationType` is an enum and v2 records no location, so
      # the catch-all is the only truthful value.
      DEFAULT_PERFORMANCE_LOCATION = "other"
      DEFAULT_MEASUREMENT_RESULT_NAME = "Measurement result"

      # `byteData`, `descriptionData` and `document` are all typed
      # `byteDataType`, so all three carry the `data` child v3 renamed.
      BYTE_DATA_DATA_XPATH = [
        "//dcc:byteData/dcc:data",
        "//dcc:descriptionData/dcc:data",
        "//dcc:document/dcc:data",
      ].join(" | ").freeze

      RENAMES = {
        "//dcc:identification/dcc:description" => "name",
        "//dcc:influenceCondition/dcc:state" => "status",
        "//dcc:previousReport/dcc:reference" => "referral",
        "//dcc:previousReport/dcc:referenceID" => "referralID",
        BYTE_DATA_DATA_XPATH => "dataBase64",
        "//dcc:formula/dcc:siunitx" => "latex",
      }.freeze

      # v2 let these `description` elements repeat; v3 allows one.
      MERGED_DESCRIPTION_PARENTS = %w[
        software item measuringEquipment usedMethod
      ].freeze

      # Elements retyped to `notEmptyStringType`, which rejects leading and
      # trailing whitespace as well as empty values.
      TRIMMED_ELEMENTS = %w[
        release model uniqueIdentifier value classID reference norm
        convention calibrationLaboratoryCode city postCode postOfficeBox
        state street streetNo eMail phone fax referralID procedure
        fileName mimeType
      ].freeze

      # Children a v2.2.1 `si:list` accepts directly; anything else in a v1
      # list body has to move into a wrapper.
      LIST_CONTAINER_CHILDREN = %w[
        label dateTime realList realListXMLList complexList
        complexListXMLList list
      ].freeze

      class << self
        # @param xml [String] DCC v2 XML.
        # @param to [String] target v3 version for `schemaVersion`.
        # @return [String] DCC v3 XML.
        def call(xml, to:)
          doc = ::Nokogiri::XML(xml)
          reject_rootless(doc)

          losses = []
          doc.root["schemaVersion"] = to
          apply_rules(doc, losses)
          report(losses)

          doc.to_xml
        end

        private

        def reject_rootless(doc)
          return if doc.root

          raise ::Dcc::ParseError,
                "Dcc::Migrate::V2ToV3 expects a DCC XML document, " \
                "got input with no root element."
        end

        def apply_rules(doc, losses)
          rename_elements(doc)
          move_ref_id_to_attribute(doc)
          add_performance_location(doc)
          add_measurement_result_names(doc)
          merge_descriptions(doc, losses)
          rehome_description_data(doc)
          trim_not_empty_strings(doc, losses)
          upgrade_dsi(doc)
          collect_losses(doc, losses)
        end

        def rename_elements(doc)
          RENAMES.each do |xpath, name|
            doc.xpath(xpath, NS).each { |node| node.name = name }
          end
        end

        def move_ref_id_to_attribute(doc)
          doc.xpath("//dcc:statement/dcc:refId | //dcc:metaData/dcc:refId", NS)
            .each do |node|
            node.parent["refId"] = node.text.strip
            node.remove
          end
        end

        def add_performance_location(doc)
          doc.xpath("//dcc:coreData", NS).each do |core_data|
            next if core_data.at_xpath("dcc:performanceLocation", NS)

            node = element(doc, "dcc:performanceLocation")
            node.content = DEFAULT_PERFORMANCE_LOCATION
            performance_anchor(core_data).add_next_sibling(node)
          end
        end

        # `endPerformanceDate` is mandatory in v2, so its absence means the
        # input is not the v2 document this transform was handed.
        def performance_anchor(core_data)
          core_data.at_xpath("dcc:endPerformanceDate", NS) ||
            raise(::Dcc::ParseError,
                  "coreData has no endPerformanceDate, so the mandatory v3 " \
                  "performanceLocation cannot be placed.")
        end

        def add_measurement_result_names(doc)
          doc.xpath("//dcc:measurementResult", NS).each do |result|
            next if result.at_xpath("dcc:name", NS)

            name = result_name(doc)
            anchor = result.children.first
            anchor ? anchor.add_previous_sibling(name) : result.add_child(name)
          end
        end

        def result_name(doc)
          name = element(doc, "dcc:name")
          content = element(doc, "dcc:content")
          content.content = DEFAULT_MEASUREMENT_RESULT_NAME
          name.add_child(content)
          name
        end

        # v2 `textType` carries an optional `@id` and real documents use it.
        # Merging removes the ids of descriptions 2..N, so every reference to
        # one is repointed at the survivor before the element goes away.
        def merge_descriptions(doc, losses)
          remap = {}
          MERGED_DESCRIPTION_PARENTS.each do |parent|
            doc.xpath("//dcc:#{parent}", NS)
              .each { |node| merge_parent_descriptions(node, remap, losses) }
          end
          repoint_references(doc, remap, losses)
        end

        def merge_parent_descriptions(node, remap, losses)
          first, *rest = node.xpath("dcc:description", NS).to_a
          rest.each do |extra|
            extra.element_children.each { |child| first.add_child(child) }
            absorb_id(first, extra, remap, losses)
            extra.remove
          end
        end

        # The survivor ends up holding the removed description's content, so a
        # reference to the removed id still means the same thing. Adopt the id
        # outright when the survivor has none.
        def absorb_id(first, extra, remap, losses)
          id = extra["id"]
          return unless id

          first["id"] ||= id
          return if first["id"] == id

          remap[id] = first["id"]
          losses << "description/@id=#{id} merged into #{first['id']}"
        end

        # Without this a `refId` would be left pointing at an id that no
        # longer exists anywhere in the document.
        def repoint_references(doc, remap, losses)
          return if remap.empty?

          doc.xpath("//*[@refId]").each do |node|
            before = node["refId"].split
            after = before.map { |token| remap.fetch(token, token) }
            next if after == before

            node["refId"] = after.join(" ")
            losses << "#{node.name}/@refId repointed to #{after.join(' ')} " \
                      "(merged descriptions)"
          end
        end

        # v3 dropped `descriptionData`; `richContentType/file` carries the
        # same `byteDataType` payload.
        def rehome_description_data(doc)
          doc.xpath(
            "//dcc:item/dcc:descriptionData | " \
            "//dcc:measuringEquipment/dcc:descriptionData", NS
          ).each do |node|
            parent = node.parent
            node.name = "file"
            description(doc, parent).add_child(node)
          end
        end

        def description(doc, parent)
          parent.at_xpath("dcc:description", NS) ||
            element(doc, "dcc:description").tap do |node|
              parent.at_xpath("dcc:name", NS).add_next_sibling(node)
            end
        end

        # `notEmptyStringType` rejects surrounding whitespace, so trimming is
        # required for validity — but it changes a value the author wrote,
        # which this transform reports rather than doing silently.
        def trim_not_empty_strings(doc, losses)
          TRIMMED_ELEMENTS.each do |name|
            doc.xpath("//dcc:#{name}", NS)
              .each { |node| trim_node(node, name, losses) }
          end
        end

        def trim_node(node, name, losses)
          return unless node.element_children.empty?

          original = node.text
          trimmed = original.strip
          reject_empty(name, original) if trimmed.empty?
          return if trimmed == original

          node.content = trimmed
          losses << "#{name} whitespace trimmed to #{trimmed.inspect} " \
                    "(v3 notEmptyStringType rejects it)"
        end

        # v2 typed these `xs:string` and accepted an empty or whitespace-only
        # value; v3's `notEmptyStringType` rejects it and there is nothing
        # truthful to put in its place.
        def reject_empty(name, original)
          raise ::Dcc::UnsupportedMigrationError,
                "Cannot migrate <dcc:#{name}>#{original}</dcc:#{name}>: v3 " \
                "types it notEmptyStringType, which rejects an empty or " \
                "whitespace-only value, and no substitute can be invented."
        end

        def upgrade_dsi(doc)
          wrap_uncertainty(doc, "expandedUnc", "expandedMU",
                           "uncertainty" => "valueExpandedMU")
          wrap_uncertainty(doc, "coverageInterval", "coverageIntervalMU",
                           "standardUnc" => "valueStandardMU")
          wrap_list_bodies(doc)
          normalize_probabilities(doc)
        end

        # Only reals OUTSIDE an `si:list`. `realInListType` misspells the
        # modern wrapper as `measurementUncertaintyUnivaraite` and accepts the
        # deprecated forms as siblings, so rewriting a list-local uncertainty
        # to the correct spelling would turn a valid document invalid. Both
        # deprecated forms stay legal in v2.2.1, so leaving them costs
        # nothing. `dcc:list` is a different element and does not match.
        def wrap_uncertainty(doc, legacy_name, modern_name, renames)
          doc.xpath("//si:real[not(ancestor::si:list)]/si:#{legacy_name}", NS)
            .each do |legacy|
            univariate = element(doc, "si:measurementUncertaintyUnivariate")
            univariate.add_child(
              modern_uncertainty(doc, legacy, modern_name, renames),
            )
            legacy.replace(univariate)
          end
        end

        def modern_uncertainty(doc, legacy, modern_name, renames)
          element(doc, "si:#{modern_name}").tap do |modern|
            legacy.element_children.each do |child|
              child.name = renames.fetch(child.name, child.name)
              modern.add_child(child)
            end
          end
        end

        # v2.2.1 `si:list` is a pure container; a v1 body moves into one
        # `si:realList` or `si:complexList`.
        def wrap_list_bodies(doc)
          doc.xpath("//si:list", NS).each do |list|
            body = list.element_children.reject do |child|
              LIST_CONTAINER_CHILDREN.include?(child.name)
            end
            next if body.empty?

            wrapper = element(doc, "si:#{list_wrapper_name(body)}")
            body.each { |child| wrapper.add_child(child) }
            list.add_child(wrapper)
          end
        end

        def list_wrapper_name(body)
          if body.any? { |child| child.name == "complex" }
            "complexList"
          else
            "realList"
          end
        end

        # D-SI v1 accepted `.95`; v2.2.1 requires a leading zero.
        def normalize_probabilities(doc)
          doc.xpath("//si:coverageProbability", NS).each do |node|
            text = node.text.strip
            node.content = "0#{text}" if text.start_with?(".")
          end
        end

        def collect_losses(doc, losses)
          collect_formula_lang(doc, losses)
          collect_extra_lab_contacts(doc, losses)
        end

        def collect_formula_lang(doc, losses)
          doc.xpath("//dcc:formula[@lang]", NS).each do |node|
            losses << "formula/@lang=#{node['lang']} " \
                      "(v3 formulae carry no language)"
            node.remove_attribute("lang")
          end
        end

        def collect_extra_lab_contacts(doc, losses)
          doc.xpath("//dcc:calibrationLaboratory", NS).each do |lab|
            extra = lab.xpath("dcc:contact", NS).to_a.drop(1)
            next if extra.empty?

            extra.each(&:remove)
            losses << "#{extra.size} extra calibrationLaboratory/contact " \
                      "(v3 allows one)"
          end
        end

        def report(losses)
          return if losses.empty?

          Kernel.warn(
            "Dcc.migrate 2.3.0 to 3.3.0 changed or discarded " \
            "#{losses.size} construct(s) v3 cannot represent as written: " \
            "#{losses.join('; ')}",
          )
        end

        def element(doc, name)
          ::Nokogiri::XML::Node.new(name, doc)
        end
      end
    end
  end
end
