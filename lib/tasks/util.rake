require 'sidekiq'

namespace :util do
	desc "Clear sidekiq Redis instance (development only!)"
	task :clear_sidekiq => :environment do
		Sidekiq.redis { |r| r.flushall }
		puts "Sidekiq redis instance cleared"
	end
end
	
