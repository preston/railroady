# frozen_string_literal: true

require 'railroady/version'
require 'railroady/options_struct'
require 'railroady/models_diagram'
require 'railroady/controllers_diagram'
require 'railroady/aasm_diagram'

# This is the RailRoady module
# TODO: documentation
module RailRoady
  require 'railroady/railtie' if defined?(Rails)
end
