# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Inspect
    # `Dcc::Inspect::Report` summarizes a parsed DCC: counts, key
    # identifiers, signature presence, and a human-readable `to_s` /
    # `to_json` / `to_yaml`.
    class Report < Lutaml::Model::Serializable
      attribute :schema_version, :string
      attribute :unique_identifier, :string
      attribute :country_code, :string
      attribute :item_count, :integer
      attribute :measurement_result_count, :integer
      attribute :quantity_count, :integer
      attribute :list_count, :integer
      attribute :embedded_file_count, :integer
      attribute :languages, :string, collection: true
      attribute :signer_count, :integer
      attribute :has_signature, :boolean

      def to_s
        lines = []
        lines << "DCC Inspection Report"
        lines << "=" * 50
        lines << "Schema version:     #{schema_version}"
        lines << "Unique identifier:  #{unique_identifier}"
        lines << "Country:            #{country_code}"
        lines << "Languages:          #{languages.join(', ')}" if languages.any?
        lines << "Items:              #{item_count}"
        lines << "Measurement results: #{measurement_result_count}"
        lines << "Quantities:         #{quantity_count}"
        lines << "Lists:              #{list_count}"
        lines << "Embedded files:     #{embedded_file_count}"
        lines << "Signers:            #{signer_count}"
        lines << "Has signature:      #{has_signature ? 'yes' : 'no'}"
        lines.join("\n")
      end

      def to_json(*_args)
        require "json"
        payload = {}
        self.class.attributes.each_key { |k| payload[k] = public_send(k) }
        ::JSON.pretty_generate(payload)
      end

      def to_yaml(*_args)
        require "yaml"
        payload = {}
        self.class.attributes.each_key { |k| payload[k] = public_send(k) }
        payload.to_yaml
      end

      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Inspect::Report]
        def call(dcc)
          admin = admin_data(dcc)
          mr_list = measurement_results(dcc)
          new(
            schema_version: dcc.schema_version.to_s,
            unique_identifier: core_data(dcc)&.unique_identifier,
            country_code: core_data(dcc)&.country_code_iso_3166_1.to_s,
            item_count: items(dcc).size,
            measurement_result_count: mr_list.size,
            quantity_count: count_quantities(mr_list),
            list_count: count_lists(mr_list),
            embedded_file_count: ::Dcc::Extract::File.each(dcc).size,
            languages: lang_codes(dcc),
            signer_count: resp_persons(dcc).size,
            has_signature: signature_present?(dcc),
          )
        end

        private

        def admin_data(dcc)
          dcc.respond_to?(:administrative_data) ? dcc.administrative_data : nil
        end

        def core_data(dcc)
          ad = admin_data(dcc)
          ad&.respond_to?(:core_data) ? ad.core_data : nil
        end

        def items(dcc)
          ad = admin_data(dcc)
          return [] unless ad&.respond_to?(:items) && ad.items&.respond_to?(:item)

          Array(ad.items.item)
        end

        def measurement_results(dcc)
          dcc.respond_to?(:measurement_results) && dcc.measurement_results&.respond_to?(:measurement_result) ?
            Array(dcc.measurement_results.measurement_result) : []
        end

        def count_quantities(mr_list)
          mr_list.sum do |mr|
            next 0 unless mr.respond_to?(:results) && mr.results&.respond_to?(:result)

            Array(mr.results.result).sum do |r|
              r.respond_to?(:data) && r.data&.respond_to?(:quantity) ? Array(r.data.quantity).size : 0
            end
          end
        end

        def count_lists(mr_list)
          mr_list.sum do |mr|
            next 0 unless mr.respond_to?(:results) && mr.results&.respond_to?(:result)

            Array(mr.results.result).sum do |r|
              r.respond_to?(:data) && r.data&.respond_to?(:list) ? Array(r.data.list).size : 0
            end
          end
        end

        def lang_codes(dcc)
          cd = core_data(dcc)
          return [] unless cd

          [cd.used_lang_code_iso_639_1, cd.mandatory_lang_code_iso_639_1].flatten.compact.map(&:to_s)
        end

        def resp_persons(dcc)
          ad = admin_data(dcc)
          return [] unless ad&.respond_to?(:resp_persons) && ad.resp_persons&.respond_to?(:resp_person)

          Array(ad.resp_persons.resp_person)
        end

        def signature_present?(dcc)
          dcc.respond_to?(:document) && dcc.document
        end
      end
    end
  end
end