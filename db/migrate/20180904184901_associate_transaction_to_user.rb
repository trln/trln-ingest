class AssociateTransactionToUser < ActiveRecord::Migration[5.1]
  def change
    add_reference :transactions, :user, foreign_key: true
    Transaction.connection.execute("UPDATE transactions SET user_id = user::integer WHERE user IS NOT NULL")
    remove_column :transactions, 'user'
  end


  
end
