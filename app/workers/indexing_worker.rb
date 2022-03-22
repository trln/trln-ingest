# Kicks off an indexing process
#
class IndexingWorker < CancellableWorker
  # rubocop:disable Metrics/MethodLength
  def perform(txn_id, batch_size = 5000)
    return if cancelled?

    begin
      Transaction.find(txn_id)
    rescue RecordNotFound
      logger.warn("Canceling invalid job #{jid} becase txn(#{txn_id}) was not found")
      cancel!(jid)
      return
    end
    processor = IndexingProcessor.from_transaction(txn_id, batch_size)
    processor.logger = logger
    processor.run
  end
  # rubocop:enable Metrics/MethodLength
end
