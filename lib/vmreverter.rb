require 'optparse'
require 'open-uri'
require 'yaml'
require 'pathname'
require 'fileutils'

require 'rubygems' unless defined?(Gem)

module Vmreverter
  $:.unshift(File.dirname(__FILE__))
  require 'vmreverter/version'

  # logger
  require 'vmreverter/logger'

  # Shared methods and helpers
  require 'vmreverter/shared'

  # hypervisor methods and helpers
  require 'vmreverter/hypervisor'

  %w( options vmmanager configuration cli ).each do |lib|
    begin
      require "vmreverter/#{lib}"
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'vmreverter', lib))
    end
  end

end
