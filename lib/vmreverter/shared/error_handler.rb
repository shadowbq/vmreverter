# Apache Licensed - (github/puppetlabs) ripped from puppet_acceptance. ** See Legal notes
# Changes include namespace swaps, method removal, method additions, and complete code refactoring

module Vmreverter
  module Shared
    module ErrorHandler

      def report_and_raise(logger, e, msg)
        logger.error "Failed: errored in #{msg}"
        logger.error(e.inspect)
        bt = e.backtrace
        logger.pretty_backtrace(bt).each_line do |line|
          logger.error(line)
        end
        if @options
          if @options[:abort]
            abort
          end  
        else
          raise e
        end
      end

    end
  end
end
