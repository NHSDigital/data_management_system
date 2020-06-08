class CreateAddress < ActiveRecord::Migration[6.0]
  def change
    create_table :addresses do |t|
      t.references :addressable, polymorphic: true
      t.string     :add1
      t.string     :add2
      t.string     :city
      t.string     :postcode
      t.string     :telephone
      t.date       :dateofaddress
      t.belongs_to :country, type: :string

      t.timestamps      
    end
  end
end
