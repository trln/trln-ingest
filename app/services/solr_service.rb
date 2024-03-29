require 'spofford'
require 'rsolr'

class SolrService
  class << self; attr_accessor :config end

  COLL_PATH = '/solr/admin/collections'

  @config = Rails.application.config_for(:solr)

  attr_accessor :url, :collection, :client

  # Create a new connection to a Solr collection.
  # if passed a block, this object will be the  block's parameter.
  def initialize(collection = 'trlnbib')
    @collection = collection
    @url = URI.join( config.url.sample, @collection).to_s
    @client = RSolr.connect :url => url
    yield self if block_given?
  end

  def config
    @config ||= Rails.application.config_for(:solr).to_ostruct_deep
  end

  def count
    response = @client.select params: { q: '*:*', rows: 0 }
  end

  def clusterstatus
    @client.get(COLL_PATH, params: { action: 'clusterstatus' })
  rescue StandardError => ex
    Rails.logger.error("unable to fetch clusterstatus: #{ex} #{ex.backtrace}")
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

  # Creates a collection if it does not
  # already exist.
  # == Parameters
  # collection::
  #   A string describing the name of the collection to create.
  #   defaults to 'trlnbib' 
  # config_name::
  #    A String with the name of the configuration name to use.
  #    A configuration matching the name must already exist.
  #    defaults to the same value as `collection`
  def create_collection(collection = 'trlnbib', config_name = nil)
    return unless Rails.env.development?

    query_resp = @client.get(COLL_PATH, params: { action: 'list' })
    return if query_resp.fetch('collections', []).include?(collection)

    config_name ||= collection

    resp = @client.get(COLL_PATH, params: { 
      action: 'create', 
      'collection.configName' => config_name,
      name: collection,
      numShards: 1
    })
    return resp
  rescue StandardError
    warn "#{query_resp.to_json}"
  end
end
