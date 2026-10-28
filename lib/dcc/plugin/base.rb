# frozen_string_literal: true

module Dcc
  module Plugin
    # Included by a plugin class so it can declare what it adds to Dcc.
    #
    # @example
    #   class MyPlugin
    #     include Dcc::Plugin::Base
    #     register_validator MyRule
    #   end
    module Base
      # @param base [Class] the including class.
      def self.included(base)
        base.extend(ClassMethods)
      end

      # `Profile#call` does `rule_class.new.check_on(dcc)`, so a validator
      # has to be a class. An instance responds to `#check_on` and so looks
      # right, but would fail deep inside validation with a message naming
      # neither the plugin nor the author's line.
      #
      # @param entry [Object] the candidate rule.
      # @raise [ArgumentError] unless entry is a class defining #check_on.
      # @return [Class] the entry.
      def self.rule_class!(entry)
        return entry if rule_class?(entry)

        raise ::ArgumentError,
              "expected a rule class responding to #check_on, " \
              "got #{describe(entry)}"
      end

      # @param entry [Object]
      # @return [Boolean]
      def self.rule_class?(entry)
        entry.is_a?(::Class) && entry.method_defined?(:check_on)
      end
      private_class_method :rule_class?

      # @param entry [Object]
      # @return [String]
      def self.describe(entry)
        return entry.inspect if entry.is_a?(::Class)

        "an instance of #{entry.class}"
      end
      private_class_method :describe

      # Declaration helpers available on the including class.
      module ClassMethods
        # Add a Schematron rule to the active validation profile.
        #
        # @param rule_class [Class] a rule class defining `#check_on(dcc)`.
        # @raise [ArgumentError] unless rule_class is such a class.
        # @return [Class] the rule class.
        def register_validator(rule_class)
          checked = ::Dcc::Plugin::Base.rule_class!(rule_class)
          ::Dcc::Plugin.register(:validators, checked)
        end
      end
    end
  end
end
