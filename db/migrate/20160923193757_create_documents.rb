class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents, id: false do |t|
      t.string :id, null: false, primary: true, limit: 32
      t.string :local_id, null: false, limit: 32
      t.string :owner, null: false, limit: 32
      t.string :collection
      t.jsonb :content
      t.string :txn_id
      t.string :updated_by
      t.timestamps
    end

    add_index :documents, :id, unique: true
    execute "ALTER TABLE documents ADD PRIMARY KEY (id)"
  end
end
