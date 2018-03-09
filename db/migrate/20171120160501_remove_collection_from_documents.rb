class RemoveCollectionFromDocuments < ActiveRecord::Migration[5.0]
  def change
    remove_column :documents, :collection, :string
  end
end
