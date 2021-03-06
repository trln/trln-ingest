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
      super(name: 'solr-validator') do |rec|
        res = @schema.analyze(rec)
        if res.empty?
          true
        else
          if @collector
            begin
              @collector.call(rec, res)
            rescue
              nil
            end
          end
          @errors += 1
          false
        end
      end
    end
  end
end
