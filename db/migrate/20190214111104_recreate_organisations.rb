class RecreateOrganisations < ActiveRecord::Migration[5.2]
  class Organisation < ApplicationRecord
  end

  def change
    create_table :organisations do |t|
      t.string     :name
      t.string     :add1
      t.string     :add2
      t.string     :city
      t.string     :postcode
      t.belongs_to :country, foreign_key: true, type: :string
      t.belongs_to :organisation_type, foreign_key: true
      t.string     :organisation_type_other

      t.timestamps
    end
  end
end
