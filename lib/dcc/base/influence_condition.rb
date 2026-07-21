# frozen_string_literal: true

module Dcc
  module Base
    # Alias: an individual `dcc:influenceCondition` element IS a Condition.
    # The XSD uses `conditionType` for the inner element. We expose both names
    # for readability at the call site.
    module InfluenceCondition
      def self.included(klass)
        klass.class_eval do
          include ::Dcc::Base::Condition
        end
      end
    end
  end
end
