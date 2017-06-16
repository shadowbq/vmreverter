module Vmreverter
  class CLI
    def initialize
      @options = Vmreverter::Options.parse_args
      @logger = Vmreverter::Logger.new(@options)
      @options[:logger] = @logger

      if @options[:lockfile]
        if Pathname.new(@options[:lockfile]).exist?
          report_and_raise(@logger, ArgumentError.new("Specified lockfile path '#{@options[:lockfile].dirname}' is locked."), "Lockfile is locked")
        end
      end

      if not @options[:config]
        report_and_raise(@logger, ArgumentError.new("Missing config, specify one (-c or --config)!"), "CLI: initialize")
      end

      @logger.debug("Options")
      @options.each do |opt, val|
        if val and val != []
          @logger.debug("\t#{opt.to_s}:")
          if val.kind_of?(Array)
            val.each do |v|
              @logger.debug("\t\t#{v.to_s}")
            end
          else
            @logger.debug("\t\t#{val.to_s}")
          end
        end
      end

      @config = Vmreverter::ConfigTester.new(@options[:config], @options)

    end

    def execute!

      begin
        trap(:INT) do
          @logger.warn "Interrupt received; exiting..."
          exit(1)
        end

        begin
          @vmmanager = Vmreverter::VMManager.new(@config, @options, @logger)
          @vmmanager.invoke
          @vmmanager.close_connection
        rescue => e
          raise e
        end

      end #trap
    end #execute!

  end
end
