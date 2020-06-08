class CreateOrganisationTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :organisation_types do |t|
      t.string :value
      t.timestamps
    end
  end
end
