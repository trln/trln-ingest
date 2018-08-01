class AddOwnerIndexToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_index :transactions, :owner
  end
end
