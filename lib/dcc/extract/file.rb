# frozen_string_literal: true

require "base64"
require "set"

module Dcc
  module Extract
    # `Dcc::Extract::File` enumerates embedded files (`dcc:byteDataType`
    # elements) inside a parsed DCC. Each entry carries the decoded binary
    # payload, MIME type, file name, and the surrounding ring.
    class File
      attr_reader :name, :file_name, :mime_type, :data, :ring

      # @param name [String, nil] human-readable name (typically from `dcc:name`).
      # @param file_name [String, nil] original file name.
      # @param mime_type [String, nil] MIME type (e.g. `text/plain`).
      # @param data [String] binary payload (decoded from base64).
      # @param ring [Symbol] one of `Dcc::Extract::Ring::ALL`.
      def initialize(name:, file_name:, mime_type:, data:, ring:)
        @name = name
        @file_name = file_name
        @mime_type = mime_type
        @data = data
        @ring = ring
      end

      # @return [Boolean] true if the embedded payload is textual (text/*).
      def text?
        mime_type.to_s.start_with?("text/")
      end

      def to_s
        "File #{file_name || '(unnamed)'} [#{ring}] (#{mime_type}, #{data.bytesize} bytes)"
      end

      class << self
        # Walk a parsed DCC and yield each embedded file in document order.
        # Detects cycles (recursive list) via object_id tracking so the walk
        # terminates for self-referential subtrees.
        # @param dcc [Lutaml::Model::Serializable]
        # @yieldparam [Dcc::Extract::File]
        # @return [Array<Dcc::Extract::File>] the list when no block given.
        def each(dcc, &block)
          list = []
          visited = ::Set.new

          collect = lambda do |node, ring|
            return unless node.is_a?(::Lutaml::Model::Serializable)
            return if visited.include?(node.object_id)

            visited << node.object_id

            new_ring =
              if admin_data?(node)
                Ring::ADMINISTRATIVE_DATA
              elsif measurement_list?(node)
                Ring::MEASUREMENT_RESULTS
              else
                ring
              end
            list << build_file(node, new_ring) if byte_data?(node)
            walk_children(node, new_ring, collect)
          end

          collect.call(dcc, nil)
          return list unless block_given?

          list.each(&block)
        end

        # @param dcc [Lutaml::Model::Serializable]
        # @param index [Integer] zero-based index.
        # @return [Dcc::Extract::File, nil]
        def at(dcc, index)
          each(dcc)[index]
        end

        # @param dcc [Lutaml::Model::Serializable]
        # @param ring [Symbol] one of Ring::ALL.
        # @return [Array<Dcc::Extract::File>]
        def in_ring(dcc, ring:)
          each(dcc).select { |f| f.ring == ring }
        end

        private

        def admin_data?(node)
          node.class.name.end_with?("::AdministrativeData")
        end

        def measurement_list?(node)
          node.class.name.end_with?("::MeasurementResultList")
        end

        def byte_data?(node)
          node.class.name.end_with?("::ByteData")
        end

        # Recursive walk: for each attribute, get its value and descend.
        # Handles both single objects and collection arrays.
        def walk_children(node, ring, walker)
          node.class.attributes.each_key do |attr_name|
            values = node.public_send(attr_name)
            next if values.nil?

            if values.is_a?(::Array)
              walk_values(values, ring, walker)
            elsif values.is_a?(::Lutaml::Model::Serializable)
              walker.call(values, ring)
            end
          end
        end

        def walk_values(values, ring, walker)
          Array(values).each do |v|
            walker.call(v, ring) if v.is_a?(::Lutaml::Model::Serializable)
          end
        end

        def build_file(byte_data, ring)
          name = extract_name(byte_data.name)
          new(
            name: name,
            file_name: byte_data.file_name,
            mime_type: byte_data.mime_type,
            data: ::Dcc::Type::Base64Binary.decode(byte_data.data_base64),
            ring: ring || Ring::ADMINISTRATIVE_DATA,
          )
        end

        def extract_name(name_obj)
          return nil unless name_obj

          first = name_obj.content.first
          return nil unless first

          values = first.value
          values.is_a?(::Array) ? values.first : values
        end
      end
    end
  end
end