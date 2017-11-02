##
# Worker that processes a transaction via Sidekiq
class TransactionWorker < CancellableWorker
  def perform(transaction_id)
    return if cancelled?
    begin
      txn = Transaction.find(transaction_id)
    rescue RecordNotFound
      logger.info("Cancelling #{jid} because no txn matches id #{transaction_id}")
      cancel!(jid)
      return
    end
    processor = TransactionProcessor.new(txn)
    processor.logger = logger
    begin
      logger.info("Starting ingest for transaction #{transaction_id}")
      processor.run
      logger.info("Starting indexer for #{transaction_id}")
      IndexingWorker.perform_async(transaction_id)
    end
  end
end
