ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# add some global functions to let configs check environment

module TRLN
  module IngestEnvironment
  
    def vagrant?
      return @vagrant if defined?(@vagrant)
      @vagrant = system('grep -q ^vagrant: /etc/passwd')
    end

    def container?
      return @container if defined?(@container)
      @container = ENV['OS_ENV'] == 'container' 
    end

    module_function :vagrant?
    module_function :container?
  end
end


if TRLN::IngestEnvironment.vagrant?
  warn "We are running under vagrant.  Subtly mangling configurations"
  ENV['VAGRANT'] = 'yes' 
end

if TRLN::IngestEnvironment.container?
  warn "We appear to be running inside a container"
end
