module Spofford
  # Creates a default SolrValidator as a filter
  class SolrValidator < Argot::Filter

    attr_reader :errors

    # Create a new solr validator
    # @param schema [String,URI,#read] the Solr schema.xml to use.  See Argot::SolrSchema for details
    # @yieldparam [Hash, Hash] the record and errors reported by the validator;    #    this block will be called for each error
    def initialize(schema = nil, &block)
      @schema = schema.nil? ? Argot::SolrSchema.new : Argot::SolrSchema.new(schema)
      @collector = block
      @errors = 0
    end

    def filter(rec)
      res = @schema.analyze(rec)
      if res.empty?
        true
      else
        @collector.call(rec, res) rescue nil if @collector
        @errors += 1
        false
      end
    end
  end
end
