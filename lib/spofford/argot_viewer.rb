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
      flat = Argot::Flattener.process(argot_content)
      Argot::Suffixer.default_instance.process(flat)
    end

    # fetches the _currently stored_ Solr content for a given
    # document ID.
    # @param doc_id [String] the unique ID of the document.
    def fetch_solr(doc_id)
      result = {}
      SolrService.new do |service|
        response = service.client.get :select, params: { q: "id:#{doc_id}" }
        dr = response['response']
        result = dr['docs'].first if dr && !dr['docs'].empty?
      end
      result
    end
  end
end
