# frozen_string_literal: true

# `Dcc::Signature` provides XMLDSig sign/verify using the `xmldsig` gem as
# a soft dependency. If the gem is not installed, attempting to use the
# signer or verifier raises `Dcc::MissingDependencyError` with installation
# instructions.
module Dcc
  module Signature
    autoload :Signer, "dcc/signature/signer"
    autoload :Verifier, "dcc/signature/verifier"
    autoload :Result, "dcc/signature/result"
  end
end