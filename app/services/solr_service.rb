require 'spofford'
require 'rsolr'

class SolrService
  class << self; attr_accessor :config end

  @config = YAML.load_file(Rails.root.join('config', 'solr.yml'))[Rails.env].to_ostruct_deep

  attr_accessor :url, :collection, :client

  # Create a new connection to a Solr collection.
  # if passed a block, this object will be the  block's parameter.
  def initialize(collection = 'trlnbib')
    @collection = collection
    @url = URI.join(self.class.config.url.sample, @collection).to_s
    @client = RSolr.connect :url => url
    yield self if block_given?
  end

  def count
    response = @client.select params: { q: '*:*', rows: 0 }
  end

  def clusterstatus
    @client.get('../admin/collections', params: { action: 'CLUSTERSTATUS' })
  rescue StandardError => ex
    Rails.logger.error("unable to fetch clusterstatus #{ex.backtrace}")
    { error: 'sorry' }
  end

  def ping
    clients = Hash[self.class.config.url.map do |host|
      uri = URI.join(host, @collection)
      hostname = uri.host
      [hostname, client]
    end]
    clients.each_with_object({}) do |(host, client), out|
      out[host] = client.get('admin/ping')
    end.to_ostruct_deep
  rescue StandardError => e
	{ message: e.to_s }
  end

  # Deletes documents from the index by ID.
  # always commits after running
  # @param ids [Array<String>] an array of IDs to delete from the Solr index
  def delete_by_ids(ids)
    @client.delete_by_id(ids)
    @client.commit
  end

  # Send an array of (concatenated) JSON files containing indexable documents
  # to the update URL for the collection.
  # @param files [Array<String>] filenames
  # @param commit_interval [Integer] number of files to submit before issuing
  # a commit; set to 0 to commit after all files are processed,
  #    and to -1 to disable commiting entirely (manual commit).
  def json_doc_update(files, commit_interval = 0)
    count = 0
    files.each do |filename|
      @client.update(
        path: 'update/json/docs',
        headers: { 'Content-Type' => 'application/json' },
        data: File.read(filename)
      )
      count += 1
      @client.commit if commit_interval > 0 && ( count % commit_interval) == 0
    end
    @client.commit unless commit_interval == -1
  end
end
