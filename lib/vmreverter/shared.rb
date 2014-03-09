
begin
  require "vmreverter/shared/error_handler"
rescue LoadError
  require File.expand_path(File.join(File.dirname(__FILE__), 'shared', file))
end

module Vmreverter
  module Shared
    include Vmreverter::Shared::ErrorHandler
  end
end
include Vmreverter::Shared
