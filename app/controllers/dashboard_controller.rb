class DashboardController < ApplicationController
  include DashboardHelper
  def index
    logger.info('dashboard index')
    @ping_results = SolrService.new.ping
    begin
      @sidekiq = { message: 'unable to query Sidekiq', running: false }
      @stats = Sidekiq::Stats.new
      @sidekiq[:stats] = @stats
      sqprocs = Sidekiq::ProcessSet.new.size
      @sidekiq[:process_count] = sqprocs
      if sqprocs.zero?
        @sidekiq[:message] = "Sidekiq does not appear to be running"
      else
        @sidekiq[:running] = true
      end
      @sidekiq[:message] = 'Sidekiq is running'
    rescue StandardError => e
      logger.error("whoa nellie, dashboard #{e.message}")
    end
  end
end
