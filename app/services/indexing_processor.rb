require 'json'
require 'argot'
require 'spofford'

class IndexingProcessor

    attr_accessor :logger

    def self.for_documents(*document_ids, batch_size)
        IndexingProcessor.new(docs: document_ids)
    end

    def self.from_transaction(txn_id, batch_size = 5000)
        IndexingProcessor.new(txn: txn_id, batch_size: batch_size)
    end

    def initialize(options={})
        @logger = options[:logger] || ( defined?(Rails) ? Rails.logger : Logger.new )
        @batch_size = options['batch_size'] || 5000
        if  options[:docs]
            @enumerator = Document.where(options[:docs]).find_each
        elsif options[:txn]
            @txn_id = options[:txn]
            @enumerator = Document.where(txn: options[:txn]).find_each
        else
            raise "instances of IndexingProcessor must be initialized with an array of document ids or a transaction id"
        end
        
    end

    def run
        logger.info "Starting run"
        contenter = Argot::Transformer.new { |doc| 
            doc.content
        }
        flattener = Argot::Transformer.new { |rec|
            Argot::Flattener.process(rec)
        }
        pipeline = Argot::Pipeline.new | contenter | flattener

        acceptable_error_rate = Rational(1,3)
        counts =  { :error => 0, :total => 0 }
        chunker = Spofford::Chunker.new(transaction_id: @txn_id, chunk_size: @batch_size) do |writer|
            logger.info "Solr output files stored in #{writer.dir}, #{writer.chunk_size} records per file"
            pipeline.run(@enumerator) do |rec|  
                begin 
                    counts[:total] += 1
                    writer.write(rec.to_json) 
                rescue StandardError => e 
                    logger.warn "unable to index record #{rec['id']} : #{e.message}"
                    error_rate = Rational(counts[:error] += 1, counts[:total]) 
                    if counts[:total] > 100 and  error_rate > acceptable_error_rate
                        raise "Error rate #{error_rate} too high, terminating"
                    end
                end
            end
        end
        logger.info "Finished creating ingest chunks, wrote #{chunker.count} records to #{chunker.files.length} files"
        SolrService.new('shared') do |solr|
            # commit only after all the files are processed
            solr.json_doc_update(chunker.files, chunker.files.length+1)
        end
        logger.info "Finished indexing"
        begin
            chunker.cleanup
        rescue StandardError => e
            logger.warn "Chunker cleanup did not exit cleanly: #{e.message}"
        end
            
    end

end


