# frozen_string_literal: true

# `Dcc::Plugin` is the registry-based extension point for the gem.
# Plugins can register custom validators, converters, or CLI commands
# without modifying the core codebase (Open/Closed Principle).
#
# @example Register a custom validator
#   Dcc::Plugin.register(:validators, MyCustomRule)
#
# @example List all registered validators
#   Dcc::Plugin.all(:validators)
module Dcc
  module Plugin
    autoload :Registry, "dcc/plugin/registry"

    class << self
      # @param category [Symbol] e.g. :validators, :converters, :cli_commands.
      # @param entry [Class, Object] the plugin to register.
      # @return [Class, Object] the entry.
      def register(category, entry)
        ::Dcc::Plugin::Registry.register(category, entry)
      end

      # @param category [Symbol]
      # @return [Array<Object>]
      def all(category)
        ::Dcc::Plugin::Registry.all(category)
      end

      # @param category [Symbol]
      # @return [Boolean]
      def any?(category)
        ::Dcc::Plugin::Registry.any?(category)
      end

      # Reset the registry (test-only helper).
      def reset!
        ::Dcc::Plugin::Registry.reset!
      end
    end
  end
end