

module Vmreverter
  # Config was taken by Ruby.
  class ConfigTester

    attr_accessor :logger
    def initialize(config_file, options)
      @options = options
      @logger = options[:logger]
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

          report_and_raise(@logger, RuntimeError.new("Missing hypervisor: (#{host})"), "ConfigTester::load_file")  unless config['HOSTS'][host].include? "hypervisor" 
          hypervisor = config['HOSTS'][host]['hypervisor'].downcase 
          #check to see if this host has a hypervisor 
          report_and_raise(@logger, RuntimeError.new("Invalid hypervisor: #{hypervisor} (#{host})"), "ConfigTester::load_file") unless Vmreverter::HYPERVISOR_TYPES.include? hypervisor
          
          #check to see if this host has a hypervisor 
          report_and_raise(@logger, RuntimeError.new("Missing snapshot: (#{host})"), "ConfigTester::load_file")  unless config['HOSTS'][host].include? "snapshot"

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
