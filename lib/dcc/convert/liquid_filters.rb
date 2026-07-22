# frozen_string_literal: true

module Dcc
  module Convert
    module LiquidFilters
      def dcc_text(content, lang = nil)
        return "" if content.nil? || content == ""

        case content
        when ::String
          content
        when ::Hash
          content["_text"] || content[:_text] || content.to_s
        when ::Array
          if lang
            entry = content.find { |c| c.is_a?(::Hash) && (c["lang"] == lang || c[:lang] == lang) }
            return dcc_text(entry, lang) if entry
          end
          first = content.find { |c| c.is_a?(::Hash) }
          first ? (first["_text"] || first[:_text] || "") : ""
        else
          content.to_s
        end
      end

      def dcc_initials(name)
        return "?" if name.nil? || name.empty?

        parts = name.split
        return parts.first[0..0].upcase if parts.size == 1

        (parts.first[0] + parts.last[0]).upcase
      end

      def dcc_count(obj)
        return 0 if obj.nil?

        case obj
        when ::Array then obj.size
        when ::Hash then 1
        else 1
        end
      end

      def dcc_items(obj)
        return [] if obj.nil?

        case obj
        when ::Array then obj
        when ::Hash then [obj]
        else [obj]
        end
      end
    end
  end
end