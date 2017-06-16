module Vmreverter
  class Options

    def self.options
      return @options
    end


    def self.parse_args
      return @options if @options

      @no_args = ARGV.empty? ? true : false

      @defaults = {}
      @options = {}
      @options_from_file = {}

      optparse = OptionParser.new do|opts|
        # Set a banner
        opts.banner = "Usage: #{File.basename($0)} #{::Vmreverter::VERSION} [options...]"

        @defaults[:auth] = File.join(ENV['HOME'], '.fog')
        opts.on '-a', '--auth FILE',
                'Use authentication FILE',
                "Default: #{@defaults[:auth]}" do |file|
          @options[:auth] = file
        end

        @defaults[:config] = nil
        opts.on '-c', '--config FILE',
                'Use configuration FILE',
                "Default: #{@defaults[:config]}" do |file|
          @options[:config] = file
        end

        @defaults[:options_file] = nil
        opts.on '-o', '--options-file FILE',
                'Read options from FILE',
                'This should evaluate to a ruby hash.',
                'CLI optons are given precedence.' do |file|
          @options_from_file = parse_options_file file
        end

        @defaults[:lockfile] = nil
        opts.on '-l', '--lockfile FILE',
                'Use a lockfile to prevent concurrency',
                '(default no lockfile).' do |file|
          @options[:lockfile] = file
        end

        @defaults[:quiet] = false
        opts.on '-q', '--[no-]quiet',
                'Do not log output to STDOUT',
                '(default: false)' do |bool|
          @options[:quiet] = bool
        end

        @defaults[:color] = true
        opts.on '--[no-]color',
                'Do not display color in log output',
                '(default: true)' do |bool|
          @options[:color] = bool
        end

        @defaults[:debug] = false
        opts.on '--[no-]debug',
                'Enable full debugging',
                '(default: false)' do |bool|
          @options[:debug] = bool
        end


        opts.on_tail("-h","--help","Display this screen") do
          puts opts
          exit
        end
      end

      optparse.parse!

      # We have use the @no_args var because OptParse consumes ARGV as it parses
      # so we have to check the value of ARGV at the begining of the method,
      # let the options be set, then output usage.
      puts optparse if @no_args

      # merge in the options that we read from the file
      @options = @options_from_file.merge(@options)
      # merge in defaults
      @options = @defaults.merge(@options)

      if @options[:lockfile]
        pn = Pathname.new(@options[:lockfile])
        unless pn.dirname.writable?
          raise ArgumentError, "Specified lockfile path '#{pn.dirname}' is not writable. Check permissions."
        end
      end

      @options
    end

    def self.parse_options_file(options_file_path)
      options_file_path = File.expand_path(options_file_path)
      unless File.exists?(options_file_path)
        raise ArgumentError, "Specified options file '#{options_file_path}' does not exist!"
      end
      # This eval will allow the specified options file to have access to our
      #  scope.  It is important that the variable 'options_file_path' is
      #  accessible, because some existing options files (e.g. puppetdb) rely on
      #  that variable to determine their own location (for use in 'require's, etc.)
      result = eval(File.read(options_file_path))
      unless result.is_a? Hash
        raise ArgumentError, "Options file '#{options_file_path}' must return a hash!"
      end

      result
    end
  end
end
