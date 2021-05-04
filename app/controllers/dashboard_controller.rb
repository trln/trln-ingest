class DashboardController < ApplicationController
  include DashboardHelper
  def index
    @reindex = ReindexRequestForm.new
    @show_confirm = true
    logger.info("Reindex: from: #{@reindex.from}, to: #{@reindex.to}") 
    solr = SolrService.new
    @ping_results = solr.ping
    @clusterstatus = solr.clusterstatus 
    @live_nodes = @clusterstatus.fetch('cluster', {}).fetch('live_nodes', [])

    begin
      @sidekiq = { message: 'unable to query Sidekiq', running: false }
      @stats = Sidekiq::Stats.new
      @sidekiq[:stats] = @stats
      sqprocs = Sidekiq::ProcessSet.new.size
      @sidekiq[:process_count] = sqprocs
      if sqprocs.zero?
        @sidekiq[:message] = 'Sidekiq does not appear to be running'
      else
        @sidekiq[:running] = true
      end
      @sidekiq[:message] = 'Sidekiq is running'
    rescue StandardError => e
      logger.error("whoa nellie, dashboard #{e.message}")
    end
  end

  def clusterstatus
    client = SolrService.new.client
    client.get('/admin/collections?action=clusterstatus')
  end

  def rerun
    rp = reindex_params
    @reindex = ReindexRequestForm.new(rp)
    @show_confirm = @reindex.invalid?
    @count = 0

    if @reindex.valid?
      if @reindex.action == 'reindex'
        @count = reindex_range
      else
        @count = reingest_range
      end
    end
  end

  def reindex_params
    params.require(:reindex_request_form).permit(:from, :to, :commit, :institution, :action)
  end

end
