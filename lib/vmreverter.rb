require 'optparse'
require 'open-uri'
require 'yaml'

require 'rubygems' unless defined?(Gem)

require 'pry'
require 'pry-nav'
module Vmreverter
  $:.unshift(File.dirname(__FILE__))

  # logger
  require 'vmreverter/logger'

  # Shared methods and helpers
  require 'vmreverter/shared'

  # hypervisor methods and helpers
  require 'vmreverter/hypervisor'

  %w( options vmmanager config_tester cli ).each do |lib|
    begin
      require "vmreverter/#{lib}"
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'vmreverter', lib))
    end
  end

end    