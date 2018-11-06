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
      raise ArgumentError, 'Instantiate with array of document ids or a transaction id'
    end
  end

  # rubocop:disable AbcSize,MethodLength
  def build_pipeline
    @deletes = []
    deleter = Argot::Filter.new do |rec|
      if rec.deleted?
        @deletes << rec.id
        false
      else
        true
      end
    end
    contenter = Argot::Transformer.new(&:content)
    flattener = Argot::Flattener.new.as_block
    suffixer = Argot::Suffixer.new.as_block

    flatten = Argot::Transformer.new(&flattener)
    suffix = Argot::Transformer.new(&suffixer)
    solr_filter = Spofford::SolrValidator.new do |rec, err|
      logger.info("Record #{rec['id']} rejected: #{err.to_json}")
    end
    Argot::Pipeline.new | deleter | contenter | flatten | suffix | solr_filter
  end
  # rubocop:enable AbcSize, MethodLength

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
    SolrService.new('trlnbib') do |solr|
      # first process any deletes
      unless @deletes.empty?
        solr.delete_by_ids(@deletes) unless @deletes.empty?
        logger.info "Sent #{@deletes.length} delete(s) to Solr"
      end
      # commit only after all the files are processed
      if chunker.count > 0
        solr.json_doc_update(chunker.files, chunker.files.length + 1)
      end
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
