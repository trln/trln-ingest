class AddPrimaryInstitutionToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :primary_institution, :string
  end
end
