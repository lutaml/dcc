# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that every `@id` on a DCC element has a matching `@refId`
        # reference and vice versa.
        class IdRefIdLinking < Base
          def check_on(dcc)
            issues = []
            ids = ::Set.new
            ref_ids = ::Set.new

            collect(dcc, ids, ref_ids)

            unused_ids = ids - ref_ids
            unused_ids.each do |id|
              issues << issue(
                severity: :warning,
                message: "@id '#{id}' is never referenced by any @refId",
              )
            end

            dangling = ref_ids - ids
            dangling.each do |rid|
              issues << issue(
                severity: :error,
                message: "@refId '#{rid}' does not match any @id",
              )
            end

            issues
          end

          private

          def collect(node, ids, ref_ids)
            return unless node.is_a?(::Lutaml::Model::Serializable)

            id = node.respond_to?(:id) ? node.id : nil
            ids << id if id && !id.empty?

            ref_id = node.respond_to?(:ref_id) ? node.ref_id : nil
            if ref_id && !ref_id.empty?
              ref_id.split(/\s+/).each { |r| ref_ids << r }
            end

            node.class.attributes.each_key do |attr|
              value = node.public_send(attr)
              Array(value).each { |c| collect(c, ids, ref_ids) }
            end
          end
        end
      end
    end
  end
end

require "set"