# Task for deleting transactions
class TransactionPurgeWorker
  include Sidekiq::Worker

  def perform(*ids)
    TransactionPurgeProcessor.new(*ids).run
  end
end
