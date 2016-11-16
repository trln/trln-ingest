##
# Worker that processes a transaction via Sidekiq
class TransactionWorker
    include Sidekiq::Worker

    def perform(transaction_id)
      txn = Transaction.find(transaction_id)
      processor = TransactionProcessor.new(txn)
      processor.logger = logger
      processor.run
    end
end


