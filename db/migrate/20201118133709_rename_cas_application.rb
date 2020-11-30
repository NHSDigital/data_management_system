class RenameCasApplication < ActiveRecord::Migration[6.0]
  def change
    rename_table :cas_applications, :cas_application_fields
  end
end
