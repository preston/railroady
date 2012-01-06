['version', 'options_struct', 'models_diagram', 'controllers_diagram', 'aasm_diagram', 'mongoid_diagram'].each { |f| require "railroady/#{f}" }

module RailRoady
  require 'railroady/railtie' if defined?(Rails)
end
