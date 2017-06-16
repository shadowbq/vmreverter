module Vmreverter
  class AWS

    #AWS support will dynamically create a Security Group for you if you specify ports in the Blimpfile, this means you can easily stand up a machine with specific ports open.
    #Blimpy uses a unique hash of the ports to avoid re-creating the Security Groups unless necessary.
    #Blimpy will import your ~/.ssh/id_rsa.pub or ~/.ssh/id_dsa.pub into a Key Pair in every region that you use in your Blimpfiles.
    def initialize(blimpy_hosts, config)
      @config = config
      @options = config[:options]
      @logger = config[:logger]
      @blimpy_hosts = blimpy_hosts
      require 'rubygems' unless defined?(Gem)
      require 'yaml' unless defined?(YAML)
      begin
        require 'blimpy'
      rescue LoadError
        raise "Unable to load Blimpy, please ensure its installed"
      end

      @fleet = Blimpy.fleet do |fleet|
        @blimpy_hosts.each do |host|
          #use snapshot provided for this host - This is an AMI!
          # host
          #   ami-size: m1.small
          #   ami-region: 'us-west-2'
          #   security-group: 'Clients'

          if not host['snapshot']
            raise "No snapshot/ami provided for AWS provisioning"
          end

          @logger.debug "Configuring hypervision AWS for host #{host.name}(#{host['snapshot']}:#{host['amisize']}) "

          fleet.add(:aws) do |ship|
            ship.name = host.name
            ship.group = host['security-group']
            ship.image_id = host['snapshot']
            ship.flavor = host['amisize'] || 'm1.small'
            ship.region = host['ami-region'] || 'us-west-2'
            ship.tags = host['tags']
            ship.username = 'root'
          end #fleet
          @logger.debug "Configuration completed."
        end #blimpy_hosts
      end#fleet

      return self
    end #init

    def invoke
      if (@config['HOSTS'][name]['launch'] == :on)
        revert
      end
    end

    def close_connection
      @fleet = nil
    end

    private

    def revert
      @logger.notify "Begin Launching AWS Hosts"

      # Attempt to start the fleet, we wrap it with some error handling that deals
      # with generic Fog errors and retrying in case these errors are transient.
      fleet_retries = 0
      begin
        @fleet.start
      rescue Fog::Errors::Error => ex
        fleet_retries += 1
        if fleet_retries <= 3
          sleep_time = rand(10) + 10
          @logger.notify("Calling fleet.destroy, sleeping #{sleep_time} seconds and retrying fleet.start due to Fog::Errors::Error (#{ex.message}), retry attempt #{fleet_retries}.")
          begin
            timeout(30) do
              @fleet.destroy
            end
          rescue
          end
          sleep sleep_time
          retry
        else
          @logger.error("Retried Fog #{fleet_retries} times, giving up and throwing the exception")
          raise ex
        end
      end
    end

    # https://github.com/rtyler/blimpy/blob/2d2c711bfcb129f5eb0346f08da62e0cfcde7917/lib/blimpy/fleet.rb#L135
    def power(toggle=:on)
      @logger.notify "Power #{toggle} AWS boxes"
      if (toggle == :off)
        start = Time.now
        @fleet.stop
        @logger.notify "Spent %.2f seconds halting" % (Time.now - start)
      elsif (toggle == :on)
        start = Time.now
        @fleet.start
        @logger.notify "Spent %.2f seconds booting" % (Time.now - start)
      else
        @logger.notify "assume power on from toggle #{toggle}"
        start = Time.now
        @fleet.start
        @logger.notify "Spent %.2f seconds booting" % (Time.now - start)
      end
    end

    def destroy
      #fleet = Blimpy.fleet do |fleet|
      #  @blimpy_hosts.each do |host|
      #    fleet.add(:aws) do |ship|
      #      ship.name = host.name
      #    end
      #  end
      #end

      @logger.notify "Destroying Blimpy boxes"
      #fleet.destroy
      @fleet.destroy
    end



  end
end
