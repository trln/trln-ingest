# Deletes transactions by ID, or all transactions
# that no longer have active records associated with them.
class TransactionPurgeProcessor
  def initialize(*ids)
    if ids.empty?
      empty_txn_sql = %{SELECT t.id from transactions t
        WHERE NOT EXISTS  ( SELECT 1 FROM documents d
           WHERE d.txn_id = t.id and not d.deleted ) AND t.created_at < current_timestamp - INTERVAL '30' DAY
         }
      @ids = ActiveRecord::Base.connection.execute(empty_txn_sql).map do |x|
        x['id'] 
      end
    end
    @ids = ids
  end

  def run
    @ids.each do |id|
      txn = Transaction.where(id: id)
      txn.destroy unless txn.nil?
    end
  end
end
