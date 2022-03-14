# frozen_string_literal: true

# Helper for use on application dashboard
module DashboardHelper
  def solrstatus_to_bootstrap_item(status)
    suffix = case status&.downcase
             when 'ok'
               'success'
             else
               'warning'
             end
    "list-group-item-#{suffix}"
  end

  def institutions
    %w[duke nccu ncsu unc]
  end

  def range_query
    Transaction.where('updated_at >? AND updated_at <?', @reindex.from, @reindex.to)
  end

  def reindex_range
    q = range_query
    q = q.where(owner: @reindex.institution) unless @reindex.institution.nil? || @reindex.institution.blank?
    return q.count unless @reindex.commit

    q.each do |tx|
      IndexingWorker.perform_async(tx.id)
    end
  end

  def reingest_range
    q = range_query
    q = q.where(owner: @institution) unless @reindex.institution.nil?
    return q.count unless @reindex.commit

    q.each do |tx|
      TransactionWorkder.perform_async(tx.id)
    end
  end
end
