# frozen_string_literal: true

module Dcc::V2
  class DigitalCalibrationCertificate < CommonElements
    include ::Dcc::Base::DigitalCalibrationCertificate
  end
  Configuration.register_model(DigitalCalibrationCertificate, id: :digitalCalibrationCertificate)
end
