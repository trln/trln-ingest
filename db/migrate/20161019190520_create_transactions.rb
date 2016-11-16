class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.string :owner
      t.string :user
      t.string :status
      t.string :tag,  length: 36
      t.string :stash_directory
      t.string :files, array: true, default: [], using: "(string_to_array(files, ','))"
      t.boolean :completed, default: false
    end
    add_index :transactions, :owner
  end
end
