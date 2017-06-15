# Kicks off an indexing process
#
class IndexingWorker
    include Sidekiq::Worker
    def perform(txn_id, batch_size=5000)
        logger.info "Creating Indexing processor for transaction(#{txn_id})"
        processor = IndexingProcessor.from_transaction(txn_id, batch_size)
        processor.logger = logger
        processor.run
    end
end
