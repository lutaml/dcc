# frozen_string_literal: true

module Dcc
  module Builder
    # A builder session tracks the current container (administrative_data,
    # items, measurement_results) and produces a fully populated
    # Dcc::V2::DigitalCalibrationCertificate or Dcc::V3::DigitalCalibrationCertificate
    # on `build`.
    class Session
      def initialize(version: 3)
        @version = version
        case version
        when 2 then ::Dcc::V2.load_all!
        when 3 then ::Dcc::V3.load_all!
        else
          raise ::Dcc::UnknownVersionError,
                "Unsupported DCC version: #{version.inspect}"
        end
        @administrative_in_progress = new_administrative_data
        @results_in_progress = []
        @items_in_progress = []
      end

      attr_reader :version

      # Top-level DSL methods. Each opens a nested container that captures
      # subsequent setter calls via instance_eval.
      def administrative_data(**attrs, &block)
        apply_attrs(@administrative_in_progress, attrs)
        instance_eval(&block) if block_given?
        @administrative_in_progress
      end

      def core_data(**attrs, &block)
        cd = new_core_data
        apply_attrs(cd, attrs)
        @administrative_in_progress.core_data = cd
        instance_eval(&block) if block_given?
        cd
      end

      def items(**attrs, &block)
        items_obj = new_items
        apply_attrs(items_obj, attrs)
        @administrative_in_progress.items = items_obj
        instance_eval(&block) if block_given?
        items_obj
      end

      def item(**attrs, &block)
        it = new_item
        apply_attrs(it, attrs)
        instance_eval(&block) if block_given?
        (@items_in_progress ||= []) << it
        # Wire into the open items container if present.
        if @administrative_in_progress&.items
          current = @administrative_in_progress.items.item
          @administrative_in_progress.items.item = Array(current) + [it]
        end
        it
      end

      def measurement_results(**_attrs, &block)
        instance_eval(&block) if block_given?
      end

      def measurement_result(**attrs, &block)
        mr = new_measurement_result
        apply_attrs(mr, attrs)
        instance_eval(&block) if block_given?
        @results_in_progress << mr
        mr
      end

      # CoreData convenience setters
      def unique_identifier(value)
        ensure_core_data.unique_identifier = value
      end

      def country_code(value)
        ensure_core_data.country_code_iso_3166_1 = value
      end

      def used_lang(value)
        cd = ensure_core_data
        cd.used_lang_code_iso_639_1 = Array(cd.used_lang_code_iso_639_1) + [value]
      end

      def mandatory_lang(value)
        cd = ensure_core_data
        cd.mandatory_lang_code_iso_639_1 = Array(cd.mandatory_lang_code_iso_639_1) + [value]
      end

      def begin_performance_date(value)
        ensure_core_data.begin_performance_date = value
      end

      def end_performance_date(value)
        ensure_core_data.end_performance_date = value
      end

      # @return [Dcc::V2::DigitalCalibrationCertificate, Dcc::V3::DigitalCalibrationCertificate]
      def build
        validate_required_sections!
        dcc = new_digital_calibration_certificate
        dcc.schema_version = @version == 2 ? "2.3.0" : "3.3.0"
        dcc.administrative_data = @administrative_in_progress
        dcc.measurement_results = new_measurement_results
        dcc.measurement_results.measurement_result = @results_in_progress
        dcc
      end

      private

      def ensure_core_data
        @administrative_in_progress.core_data ||= new_core_data
      end

      def validate_required_sections!
        unless @administrative_in_progress&.core_data
          raise ::Dcc::BuilderError,
                "administrative_data.core_data is required"
        end
        return if @administrative_in_progress.items

        raise ::Dcc::BuilderError,
              "administrative_data.items is required"
      end

      def apply_attrs(target, attrs)
        attrs.each do |k, v|
          setter = :"#{k}="
          target.public_send(setter, v) if Dcc::TypeGuards.has_attribute?(target, setter)
        end
      end

      def version_module
        @version == 2 ? ::Dcc::V2 : ::Dcc::V3
      end

      def new_digital_calibration_certificate
        version_module::DigitalCalibrationCertificate.new
      end

      def new_administrative_data
        version_module::AdministrativeData.new
      end

      def new_core_data
        version_module::CoreData.new
      end

      def new_items
        version_module::ItemList.new
      end

      def new_item
        version_module::Item.new
      end

      def new_measurement_results
        version_module::MeasurementResultList.new
      end

      def new_measurement_result
        version_module::MeasurementResult.new
      end
    end
  end
end