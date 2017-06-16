# Apache Licensed - (github/puppetlabs) ripped from puppet_acceptance. ** See Legal notes
# Changes include namespace swaps, and refactoring

class VsphereHelper

  #Class methods
  def self.load_config authfile
    vsphere_credentials = {}

    if File.exists?(authfile)
      vInfo = YAML.load_file(authfile)
    elsif File.exists?( File.join(ENV['HOME'], '.fog') )
      vInfo = YAML.load_file( File.join(ENV['HOME'], '.fog') )
    else
      report_and_raise(@logger, RuntimeError.new("Couldn't authentication for vSphere in auth file !"), "VSphereHelper::load_config")
    end

    begin
      vsphere_credentials[:server] = vInfo[:default][:vsphere_server]
      vsphere_credentials[:user]   = vInfo[:default][:vsphere_username]
      vsphere_credentials[:pass]   = vInfo[:default][:vsphere_password]
    rescue
      report_and_raise(@logger, RuntimeError.new("Couldn't load authentication for vSphere in auth file !"), "VSphereHelper::load_config")
    end

    return vsphere_credentials
  end

  def initialize(vInfo, logger)

    @logger = logger
    begin
      require 'rbvmomi'
    rescue LoadError
      raise "Unable to load RbVmomi, please ensure its installed"
    end

    # If you don’t have trusted SSL certificates installed on the host you’re connecting to,
    #you’ll get an +OpenSSL::SSL::SSLError+ “certificate verify failed”.
    #You can work around this by using the :insecure option to +RbVmomi::VIM.connect+.

    @connection = RbVmomi::VIM.connect :host     => vInfo[:server],
                                       :user     => vInfo[:user],
                                       :password => vInfo[:pass],
                                       :insecure => true
  end
  #Instance Methods
  def find_snapshot vm, snapname
    search_child_snaps vm.snapshot.rootSnapshotList, snapname
  end

  def search_child_snaps tree, snapname
    snapshot = nil
    tree.each do |child|
      if child.name == snapname
        snapshot ||= child.snapshot
      else
        snapshot ||= search_child_snaps child.childSnapshotList, snapname
      end
    end
    snapshot
  end

  def find_customization name
    csm = @connection.serviceContent.customizationSpecManager

    begin
      customizationSpec = csm.GetCustomizationSpec({:name => name}).spec
    rescue
      customizationSpec = nil
    end

    return customizationSpec
  end

  # an easier wrapper around the horrid PropertyCollector interface,
  # necessary for searching VMs in all Datacenters that may be nested
  # within folders of arbitrary depth
  # returns a hash array of <name> => <VirtualMachine ManagedObjects>
  def find_vms names, connection = @connection
    names = names.is_a?(Array) ? names : [ names ]
    containerView = get_base_vm_container_from connection
    propertyCollector = connection.propertyCollector

    objectSet = [{
      :obj => containerView,
      :skip => true,
      :selectSet => [ RbVmomi::VIM::TraversalSpec.new({
          :name => 'gettingTheVMs',
          :path => 'view',
          :skip => false,
          :type => 'ContainerView'
      }) ]
    }]

    propSet = [{
      :pathSet => [ 'name' ],
      :type => 'VirtualMachine'
    }]

    results = propertyCollector.RetrievePropertiesEx({
      :specSet => [{
        :objectSet => objectSet,
        :propSet   => propSet
      }],
      :options => { :maxObjects => nil }
    })

    vms = {}
    results.objects.each do |result|
      name = result.propSet.first.val
      next unless names.include? name
      vms[name] = result.obj
    end

    while results.token do
      results = propertyCollector.ContinueRetrievePropertiesEx({:token => results.token})
      results.objects.each do |result|
        name = result.propSet.first.val
        next unless names.include? name
        vms[name] = result.obj
      end
    end
    vms
  end

  def find_datastore datastorename
    datacenter = @connection.serviceInstance.find_datacenter
    datacenter.find_datastore(datastorename)
  end

  def find_folder foldername
    datacenter = @connection.serviceInstance.find_datacenter
    base = datacenter.vmFolder
    folders = foldername.split('/')
    folders.each do |folder|
      case base
        when RbVmomi::VIM::Folder
          base = base.childEntity.find { |f| f.name == folder }
        else
          abort "Unexpected object type encountered (#{base.class}) while finding folder"
      end
    end

    base
  end

  def find_pool poolname
    datacenter = @connection.serviceInstance.find_datacenter
    base = datacenter.hostFolder
    pools = poolname.split('/')
    pools.each do |pool|
      case base
        when RbVmomi::VIM::Folder
          base = base.childEntity.find { |f| f.name == pool }
        when RbVmomi::VIM::ClusterComputeResource
          base = base.resourcePool.resourcePool.find { |f| f.name == pool }
        when RbVmomi::VIM::ResourcePool
          base = base.resourcePool.find { |f| f.name == pool }
        else
          abort "Unexpected object type encountered (#{base.class}) while finding resource pool"
      end
    end

    base = base.resourcePool unless base.is_a?(RbVmomi::VIM::ResourcePool) and base.respond_to?(:resourcePool)
    base
  end

  def get_base_vm_container_from connection
    viewManager = connection.serviceContent.viewManager
    viewManager.CreateContainerView({
      :container => connection.serviceContent.rootFolder,
      :recursive => true,
      :type      => [ 'VirtualMachine' ]
    })
  end

  def close_connection
    @connection.close
  end
end
