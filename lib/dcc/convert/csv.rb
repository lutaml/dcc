# frozen_string_literal: true

require "csv"

module Dcc
  module Convert
    # `Dcc::Convert::Csv` flattens a parsed DCC into a tabular CSV with
    # one row per measurement quantity.
    module Csv
      HEADERS = %w[result_name quantity_name quantity_type value unit uncertainty coverage_factor].freeze

      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Convert::Result]
        def call(dcc)
          rows = collect_quantities(dcc)
          payload = ::CSV.generate do |csv|
            csv << HEADERS
            rows.each { |row| csv << row }
          end

          ::Dcc::Convert::Result.new(
            format: :csv,
            payload: payload,
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end

        private

        def collect_quantities(dcc)
          rows = []
          return rows unless Dcc::TypeGuards.has_attribute?(dcc, :measurement_results)

          Array(dcc.measurement_results.measurement_result).each do |mr|
            mr_name = name_of(mr)
            next unless Dcc::TypeGuards.has_attribute?(mr, :results)

            Array(mr.results.result).each do |r|
              result_name = name_of(r)
              next unless Dcc::TypeGuards.has_attribute?(r, :data)

              Array(r.data).each do |d|
                walk_data(d, mr_name, result_name, rows)
              end
            end
          end
          rows
        end

        def walk_data(data, mr_name, result_name, rows)
          walk_quantities(Array(data.quantity), mr_name, result_name, rows)
          Array(data.list).each do |list|
            walk_quantities(Array(list.quantity), mr_name, result_name, rows)
            Array(list.list).each { |sub| walk_data(sub, mr_name, result_name, rows) }
          end
        end

        def walk_quantities(quantities, mr_name, result_name, rows)
          quantities.each do |q|
            push_quantity(q, mr_name, result_name, "real", rows)
          end
        end

        def push_quantity(q, mr_name, result_name, kind, rows)
          rows << [
            mr_name, name_of(q), kind,
            value_of(q), unit_of(q), uncertainty_of(q), k_factor_of(q),
          ]
        end

        def name_of(node)
          return "" unless node && Dcc::TypeGuards.has_attribute?(node, :name)
          return "" unless node.name

          content = Dcc::TypeGuards.has_attribute?(node.name, :content) ? node.name.content : []
          first = Array(content).first
          return "" unless first

          vals = Dcc::TypeGuards.has_attribute?(first, :value) ? first.value : []
          Array(vals).first.to_s
        end

        def value_of(q)
          reals = Array(q.real)
          return reals.first.value.to_s if reals.any?

          lists = Array(q.real_list_xml_list)
          return lists.first.value_xml_list.map(&:to_s).join("; ") if lists.any?

          ""
        end

        def unit_of(q)
          reals = Array(q.real)
          return reals.first.unit.to_s if reals.any? && reals.first.unit

          lists = Array(q.real_list_xml_list)
          return lists.first.unit_xml_list.to_s if lists.any? && lists.first.unit_xml_list

          ""
        end

        def uncertainty_of(q)
          reals = Array(q.real)
          return "" if reals.empty? || !reals.first.measurement_uncertainty_univariate

          mu = reals.first.measurement_uncertainty_univariate
          return mu.expanded_mu.value_expanded_mu.to_s if mu.expanded_mu
          return mu.standard_mu.value_standard_mu.to_s if mu.standard_mu
          return mu.coverage_interval_mu.value_standard_mu.to_s if mu.coverage_interval_mu

          ""
        end

        def k_factor_of(q)
          reals = Array(q.real)
          return "" if reals.empty?

          mu = reals.first.measurement_uncertainty_univariate
          return "" unless mu&.expanded_mu

          mu.expanded_mu.coverage_factor.to_s
        end
      end
    end
  end
end