module Spofford
  # Argot transformer that adds a timestamp of ingest 
  # to all records.
  class Timestamper
    include Argot::Methods

    # since the intent is to put this after
    # all the other filters in the indexing 
    # pipeline, we'll write the fully
    # qualified field name; will be available as 'index_date'
    # in Solr documents
    FIELD_NAME = 'index_date_dt_stored_single'

    def initialize
      @timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    def process(input)
      input[FIELD_NAME] = @timestamp
      input
    end

    alias call process
  end
end
