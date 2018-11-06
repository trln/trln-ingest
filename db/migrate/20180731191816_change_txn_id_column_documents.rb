class ChangeTxnIdColumnDocuments < ActiveRecord::Migration[5.1]
  def change
    change_column :documents, :txn_id, 'integer USING CAST(txn_id AS integer)'
  end
end
