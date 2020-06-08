class CreateOrganisations < ActiveRecord::Migration[5.2]
  def change
    create_table :organisations do |t|
      t.string     :name
      t.string     :department
      t.string     :add1
      t.string     :add2
      t.string     :city
      t.string     :postcode
      t.references :country
      t.references :organisation_type
      t.string     :organisation_type_other

      t.timestamps
    end
  end
end
