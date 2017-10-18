class AddApprovedToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :approved, :boolean, default: false, null: false
  end
end
