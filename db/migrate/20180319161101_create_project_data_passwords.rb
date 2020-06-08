# Create tables for storing passwords for data batch encryption / extraction
class CreateProjectDataPasswords < ActiveRecord::Migration[5.0]
  def change
    create_table :project_data_passwords do |t|
      t.references :project, foreign_key: true
      t.binary :rawdata
      t.datetime :expired

      t.timestamps
    end
  end
end
