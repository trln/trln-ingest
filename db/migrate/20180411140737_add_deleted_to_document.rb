class AddDeletedToDocument < ActiveRecord::Migration[5.1]
  def up
    add_column :documents, :deleted, :boolean, default: false
  end

  def down
    remove_column :documents, :deleted
  end
end
