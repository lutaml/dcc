# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:statementListType` — collection of `dcc:statement`.
    module StatementList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :statement, :statement, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "statements"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "statement", to: :statement
          end
        end
      end
    end
  end
end
