require 'json'
require 'argot'
require 'spofford'

# Converts Documents from a Transaction into Solr documents and
#  sends them to Solr
class IndexingProcessor
  attr_accessor :logger

  def self.for_documents(*document_ids)
    IndexingProcessor.new(docs: document_ids)
  end

  def self.from_transaction(txn_id, batch_size = 5000)
    IndexingProcessor.new(txn: txn_id, batch_size: batch_size)
  end

  def initialize(options = {})
    @logger = options[:logger] || (defined?(Rails) ? Rails.logger : Logger.new)
    @batch_size = options['batch_size'] || 5000
    if options[:docs]
      @enumerator = Document.where(options[:docs]).find_each
    elsif options[:txn]
      @txn_id = options[:txn]
      @transaction = Transaction.find(@txn_id)
      @enumerator = Document.where(txn: options[:txn]).find_each
    else
      raise 'Instantiate with array of document ids or a transaction id'
    end
  end

  # rubocop:disable AbcSize
  def build_pipeline
    contenter = Argot::Transformer.new(&:content)
    flattener = Argot::Transformer.new { |rec| Argot::Flattener.process(rec) }
    suffixer_instance = Argot::Suffixer.default_instance
    suffixer = Argot::Transformer.new { |rec| suffixer_instance.process(rec) }
    solr_filter = Spofford::SolrValidator.new do |rec, err|
      logger.info("Record #{rec['id']} rejected: #{err.to_json}")
    end
    Argot::Pipeline.new | contenter | flattener | suffixer | solr_filter
  end

  def run
    logger.info 'Starting run'
    @transaction.update(status: 'Indexing') if @transaction
    pipeline = build_pipeline
    acceptable_error_rate = Rational(1, 3)
    counts =  { error: 0, total: 0 }
    chunker = Spofford::Chunker.new(transaction_id: @txn_id, chunk_size: @batch_size) do |writer|
      logger.info "Solr output files stored in #{writer.dir}, #{writer.chunk_size} records per file"
      pipeline.run(@enumerator) do |rec|
        begin
          counts[:total] += 1
          writer.write(rec.to_json)
        rescue StandardError => e
          logger.warn("unable to index record #{rec['id']} : #{e.message}")
          error_rate = Rational(counts[:error] += 1, counts[:total])
          if counts[:total] > 100 && error_rate > acceptable_error_rate
            raise "Error rate #{error_rate} too high, terminating"
          end
        end
      end
    end
    logger.info "Wrote #{chunker.count} records to #{chunker.files.length} files"
    #unless solr_filter.errors.zero?
    #  logger.warn('Some flattened documents were not sent to solr')
    #end
    SolrService.new('shared') do |solr|
      # commit only after all the files are processed
      solr.json_doc_update(chunker.files, chunker.files.length + 1)
    end
    logger.info 'Finished indexing'
    begin
      chunker.cleanup
    rescue StandardError => e
      logger.warn "Chunker cleanup did not exit cleanly: #{e.message}"
    ensure
      @transaction.update(status: 'Complete') if @transaction
    end
  end
end
