##
# Worker that processes a transaction via Sidekiq
class TransactionWorker
    include Sidekiq::Worker

    def perform(transaction_id)
      txn = Transaction.find(transaction_id)
      processor = TransactionProcessor.new(txn)
      processor.logger = logger
      begin
        processor.run
        logger.info("Starting indexer for #{transaction_id}")
        IndexingWorker.perform_async(transaction_id)
      end
    end
end


