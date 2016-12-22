require 'spofford'
require 'rsolr'

class SolrService
    class << self; attr_accessor :config end

    @config = YAML.load_file(Rails.root.join('config', 'solr.yml'))[Rails.env].to_ostruct_deep

    attr_accessor :url, :collection, :client
    
    # Create a new connection to a Solr collection.
    # if passed a block, this object will be the  block's parameter.
    def initialize(collection='shared')
        @collection= SolrService.config.collections[collection]
        raise "No collection with the logical name '#{collection}' defined in environment '#{Rails.env}'" unless @collection
        @url = URI.join(SolrService.config.url, @collection).to_s
        @client = RSolr.connect :url => url
        if block_given?
            yield self
        end
    end

    # Send an array of (concatenated) JSON files containing indexable documents
    # to the update URL for the collection.
    # @param files [Array<String>] filenames
    # @param commit_interval [Integer] number of files to submit before issuing a commit; set to 0 to commit after all files are processed,
    #    and to -1 to disable commiting entirely (manual commit).
    def json_doc_update(files,commit_interval =1) 
        count = 0
        files.each do |filename|
            @client.update(:path => 'update/json/docs', :headers => { 'Content-Type' => 'application/json' }, :data => File.read(filename))
            count += 1
            if commit_interval >= 0 and (count % commit_interval) ==0 and 
                @client.commit
            end
        end
        @client.commit unless commit_interval == -1
    end
end
