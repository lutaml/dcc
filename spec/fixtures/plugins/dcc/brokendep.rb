# frozen_string_literal: true

# Stands in for a plugin whose entry file loads fine but whose own
# dependency is missing. `Dcc.load_plugins` must let this LoadError
# through rather than reporting this file as the one it could not find.
require "a_gem_that_does_not_exist"
