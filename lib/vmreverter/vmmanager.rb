%w(hypervisor).each do |lib|
  begin
    require "vmreverter/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

module Vmreverter
  
  HYPERVISOR_TYPES = ['vsphere', 'aws']
  
  #Collection using Proxy Pattern - Proxy normalized access to specific Hypervisors such as VSphere through creation by the Hypervisor Factory
  class VMManager

    attr_accessor :hypervisor_collection

    def initialize(config, options, logger)
      @logger = logger
      @options = options
      @hosts = []
      @config = config
      @hypervisor_collection = {}
      @virtual_machines = {}

      @config['HOSTS'].each_key do |name|
        hypervisor = @config['HOSTS'][name]['hypervisor'] 
        @logger.debug "Hypervisor for #{name} is #{hypervisor}"
        @virtual_machines[hypervisor] = [] unless @virtual_machines[hypervisor]
        @virtual_machines[hypervisor] << name
      end

      ## Data Model Looks like 
      # @virtual_machines.inspect
      # {"vsphere" => ["test_server01","test_server02"], "blimpy" => ["aws_test_server01","aws_test_server01"]}

      @virtual_machines.each do |type, names|
        @hypervisor_collection[type] = Vmreverter::Hypervisor.register(type, names, @options, @config)
      end

      #return instance created
      return self
    end

    def invoke 
      @hypervisor_collection.each do |hypervisor_type, hypervisor_instance|
        @logger.notify("Invoking #{hypervisor_type} hosts") 
        hypervisor_instance.invoke
      end
    end

    def close_connection
      @hypervisor_collection.each do |hypervisor_type, hypervisor_instance|
        @logger.notify("Disconnecting from #{hypervisor_type}") 
        hypervisor_instance.close_connection
      end
    end

  end
end
