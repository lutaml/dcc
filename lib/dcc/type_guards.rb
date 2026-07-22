# frozen_string_literal: true

# `Dcc::TypeGuards` provides type-safe introspection helpers that replace
# `respond_to?` (banned per project rule) with explicit `is_a?` checks.
# Each helper returns true/false without raising.
module Dcc
  module TypeGuards
    module_function

    # True if `node` is any version of DCC root.
    def digital_calibration_certificate?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::DigitalCalibrationCertificate")
    end

    # True if `node` has an `administrative_data` attribute (DCC root only).
    def has_administrative_data?(node)
      digital_calibration_certificate?(node)
    end

    # True if `node` is a `MeasurementResultList` (any version).
    def measurement_result_list?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::MeasurementResultList")
    end

    # True if `node` is an `AdministrativeData` (any version).
    def administrative_data?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::AdministrativeData")
    end

    # True if `node` is a `CoreData` (any version).
    def core_data?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::CoreData")
    end

    # True if `node` is a `RespPersonList` (any version).
    def resp_person_list?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::RespPersonList")
    end

    # True if `node` is a `RespPerson` (any version).
    def resp_person?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::RespPerson")
    end

    # True if `node` is a `SoftwareList` (any version).
    def software_list?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::SoftwareList")
    end

    # True if `node` is a `Software` (any version).
    def software?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::Software")
    end

    # True if `node` is a `RealListXmlList` (any version).
    def real_list_xml_list?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::RealListXmlList")
    end

    # True if `node` is a `Text` (any version).
    def text?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::Text")
    end

    # True if `node` is a `MeasurementResult` (any version).
    def measurement_result?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::MeasurementResult")
    end

    # True if `node` is a `ByteData` (any version).
    def byte_data?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::ByteData")
    end

    # True if `node` is a `Quantity` (any version).
    def quantity?(node)
      return false unless node.is_a?(::Lutaml::Model::Serializable)

      node.class.name.end_with?("::Quantity")
    end

    # Safe attribute reader: returns the value or nil if the node doesn't
    # have the attribute. Uses explicit class introspection rather than
    # `respond_to?`.
    def read_attribute(node, name)
      return nil unless node.is_a?(::Lutaml::Model::Serializable)
      return nil unless node.class.attributes.key?(name)

      node.public_send(name)
    end

    # Safe method call: invokes the method if the node's class declares it.
    def call_if_present(node, method_name, *args)
      return nil unless node.is_a?(::Lutaml::Model::Serializable)
      return nil unless node.class.method_defined?(method_name) ||
                        node.class.method_defined?(:"#{method_name}=")

      node.public_send(method_name, *args)
    end
  end
end