module Spofford
  # Provides different views of an Argot document.
  module ArgotViewer
    # converts a document from stored Argot
    # to what would be submitted to Solr at
    # index time.  This method is NOT designed
    # to be used in bulk.
    # @param argot_content [Hash] the Argot data structure to be rendered
    # @return [Hash] the flattened and suffixed result.
    def prepare_for_ingest(argot_content)
      flat = Argot::Flattener.new.call(argot_content)
      Argot::Suffixer.new.call(flat)
    end

    # fetches the _currently stored_ Solr content for a given
    # document ID.
    # @param doc_id [String] the unique ID of the document.
    def fetch_solr(doc_id)
      result = {}
      SolrService.new do |service|
        response = service.client.get :document, params: { id: doc_id }
        dr = response['response']
        result = dr['docs'].first if dr && !dr['docs'].empty?
      end
      result
    end

    # Fetch 'LukeHandler' detailed document view from Solr
    # @param doc_id [String] the ID of the document
    def fetch_luke_doc(doc_id)
      result = { data: 'Unable to fetch data from Solr index' }
      begin
        SolrService.new do |service|
          res = service.client.get 'admin/luke', params: { id: doc_id }
          result = res['doc'] if res.key?('doc')
        end
      rescue StandardError => e
        warn("Luke handler error #{e}")
      end
      result
    end
  end
end
