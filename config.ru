# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

map '/spofford'  do
	run Rails.application
end
