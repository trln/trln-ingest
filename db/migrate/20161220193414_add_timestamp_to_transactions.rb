class AddTimestampToTransactions < ActiveRecord::Migration[5.0]
  def change
    change_table(:transactions) do |t| 
      t.timestamps
    end
  end
end
