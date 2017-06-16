require 'singleton'

module Vmreverter
  # Config was taken by Ruby.
  class Configuration
    include Singleton

    attr_reader :logger, :options, :config

    def self.build(options, logger)
      @@options = options
      @@logger = logger
    end

    def initialize
      @options = @@options
      @logger = @@logger
      config_file = @options[:config]
      @config = load_file(config_file)
    end

    def [](key)
      @config[key]
    end

    def load_file(config_file)
      if config_file.is_a? Hash
        config = config_file
      else
        config = YAML.load_file(config_file)

        # Make sure the tag array is present for all hosts
        config['HOSTS'].each_key do |host|
          config['HOSTS'][host]['tags'] ||= []

          report_and_raise(@logger, RuntimeError.new("Missing hypervisor: (#{host})"), "Configuration::load_file")  unless config['HOSTS'][host].include? "hypervisor"
          hypervisor = config['HOSTS'][host]['hypervisor'].downcase
          #check to see if this host has a hypervisor
          report_and_raise(@logger, RuntimeError.new("Invalid hypervisor: #{hypervisor} (#{host})"), "Configuration::load_file") unless Vmreverter::HYPERVISOR_TYPES.include? hypervisor

          #check to see if this host has a hypervisor
          report_and_raise(@logger, RuntimeError.new("Missing snapshot: (#{host})"), "Configuration::load_file")  unless config['HOSTS'][host].include? "snapshot"

        end

      end

      # Merge some useful date into the config hash
      config['CONFIG'] ||= {}

      config
    end


    # Print out test configuration
    def dump

      # Access "tags" for each host
      @config["HOSTS"].each_key do|host|
        @config["HOSTS"][host]['tags'].each do |tag|
          @logger.notify "Tags for #{host} #{tag}"
        end
      end

      # Access @config keys/values
      @config["CONFIG"].each_key do|cfg|
          @logger.notify "Config Key|Val: #{cfg} #{@config["CONFIG"][cfg].inspect}"
      end
    end
  end
end
