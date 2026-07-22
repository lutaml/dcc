# frozen_string_literal: true

module Dcc
  module Plugin
    # Category-based registry. Each category (validators, converters,
    # cli_commands) gets its own array. Thread-safe via a Mutex.
    class Registry
      @categories = ::Hash.new { |h, k| h[k] = [] }
      @mutex = ::Mutex.new

      class << self
        # @param category [Symbol]
        # @param entry [Class, Object]
        # @return [Class, Object]
        def register(category, entry)
          @mutex.synchronize do
            @categories[category.to_sym] << entry
            entry
          end
        end

        # @param category [Symbol]
        # @return [Array<Object>]
        def all(category)
          @mutex.synchronize { @categories[category.to_sym].dup }
        end

        # @param category [Symbol]
        # @return [Boolean]
        def any?(category)
          @mutex.synchronize { !@categories[category.to_sym].empty? }
        end

        def reset!
          @mutex.synchronize { @categories.clear }
        end

        # @return [Array<Symbol>] the registered category names.
        def categories
          @mutex.synchronize { @categories.keys.dup }
        end
      end
    end
  end
end