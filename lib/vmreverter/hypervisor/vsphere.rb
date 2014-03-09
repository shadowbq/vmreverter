# Apache Licensed - (github/puppetlabs) ripped from puppet_acceptance. ** See Legal notes
# Changes include namespace swaps, method removal, method additions, and complete code refactoring
module Vmreverter 
  class Vsphere

    def initialize(vsphere_hosts, options, config)
      @options = options
      @config = config
      @logger = options[:logger]
      @vsphere_hosts = vsphere_hosts
      require 'yaml' unless defined?(YAML)
      vsphere_credentials = VsphereHelper.load_config options[:auth]

      @logger.notify "Connecting to vSphere at #{vsphere_credentials[:server]}" + " with credentials for #{vsphere_credentials[:user]}"

      @vsphere_helper = VsphereHelper.new( vsphere_credentials )

      #Transpose Hash for @vsphere_vms = {"test-server01" => "gold-image", "test-server02" => "silver-image"}
      @vsphere_vms = {}
      @vsphere_hosts.each do |host|
        @vsphere_vms[host] = config['HOSTS'][host]['snapshot']
      end

      #Index Hosts Available via rbvmomi
      vms = @vsphere_helper.find_vms(@vsphere_vms.keys)
      
      # Test if host exists and host's snapshot requested exists
      @vsphere_vms.each_pair do |name, snap|
        #Find Host in Index
        report_and_raise(@logger, RuntimeError.new("Couldn't find VM #{name} in vSphere!"), "VSphere::initialize") unless vm = vms[name]
        #snap ~> config['HOSTS'][vm]['snapshot']
        report_and_raise(@logger, RuntimeError.new("Could not find snapshot '#{snap}' for VM #{vm.name}!"), "VSphere::initialize")  unless @vsphere_helper.find_snapshot(vm, snap) 
      end

      return self    
    end

    def invoke 
      revert
    end

    def close_connection
      @vsphere_helper.close_connection
    end

    private 
    
    def revert
      @logger.notify "Begin Reverting"
      @vsphere_vms.each_pair do |name, snap|        

        vm = @vsphere_helper.find_vms(@vsphere_vms.keys)[name]
        @logger.notify "Reverting #{vm.name} to snapshot '#{snap}'"
        start = Time.now
        
        # This will block for each snapshot...
        # The code to issue them all and then wait until they are all done sucks
        snapshot = @vsphere_helper.find_snapshot(vm, snap)
        snapshot.RevertToSnapshot_Task.wait_for_completion

        time = Time.now - start
        @logger.notify "Spent %.2f seconds reverting" % time
        
        if (@config['HOSTS'][name]['power'] == 'up')
          host_power_on(vm)
        elsif (@config['HOSTS'][name]['power'] == 'down')
          host_power_off(vm)
        else
          @logger.notify "VM #{name} defaulting to snapshot '#{snap}' power setting"
        end

      end
    end

    def host_power_on(vm)
        unless vm.runtime.powerState == "poweredOn"
          @logger.notify "Booting #{vm.name}"
          start = Time.now
          vm.PowerOnVM_Task.wait_for_completion
          @logger.notify "Spent %.2f seconds booting #{vm.name}" % (Time.now - start)
        end
    end

    def host_power_off(vm)
        unless vm.runtime.powerState == "poweredOff"
          @logger.notify "Shutting down #{vm.name}"
          start = Time.now
          vm.PowerOffVM_Task.wait_for_completion
          @logger.notify "Spent %.2f seconds halting #{vm.name}" % (Time.now - start)
        end
    end

    

  end
end
