# frozen_string_literal: true

require 'railroady'
require 'rails'

module RailRoady
  class Railtie < Rails::Railtie
    rake_tasks do
      f = File.join(File.dirname(__FILE__), '..', '..', 'tasks', 'railroady.rake')
      load f
      # load 'tasks/railroady.rake'
    end
  end
end
