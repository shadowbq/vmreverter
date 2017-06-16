# Apache Licensed - (github/puppetlabs) ripped from puppet_acceptance. ** See Legal notes
# Changes include namespace swaps, method removal, method additions, and complete code refactoring

module Vmreverter

  # Factory Pattern - Class to generate the correct hypervisor object, given type
  class Hypervisor

    def configure(hosts)
      @logger.debug "No post-provisioning configuration necessary for #{self.class.name} boxes"
    end

    def self.register(type, hosts_to_provision, config)
      @logger = config[:logger]
      @logger.notify("Hypervisor found some #{type} boxes to hook")
      case type.downcase
        when /vsphere/
          return Vmreverter::Vsphere.new(hosts_to_provision, config)
        when /aws/
          return Vmreverter::AWS.new(hosts_to_provision, config)
        else
          report_and_raise(@logger, RuntimeError.new("Missing Class for hypervisor invocation: (#{type})"), "Hypervisor::register")
      end
    end
  end
end

%w( vsphere_helper aws vsphere ).each do |lib|
  begin
    require "hypervisor/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), "hypervisor", lib))
  end
end
