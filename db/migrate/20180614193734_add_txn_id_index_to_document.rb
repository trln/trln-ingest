class AddTxnIdIndexToDocument < ActiveRecord::Migration[5.1]
  def change
    add_index :documents, :txn_id
  end
end
