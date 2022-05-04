##
# Worker that processes a transaction via Sidekiq
class TransactionWorker < CancellableWorker
  sidekiq_options log_level: :debug

  def perform(transaction_id)
    return if cancelled?
    begin
      txn = Transaction.find(transaction_id)
    rescue ActiveRecord::RecordNotFound
      logger.info("Cancelling #{jid} because no txn matches id #{transaction_id}")
      cancel!(jid)
      return
    end
    logger.info("Creating a processor for #{transaction_id}")
    processor = TransactionProcessor.new(txn)
    #processor.logger = logger
    begin
      logger.info("Starting ingest for transaction #{transaction_id}")
      processor.run
      logger.info("Starting indexer for #{transaction_id}")
      IndexingWorker.perform_async(transaction_id)
    end
  end
end
