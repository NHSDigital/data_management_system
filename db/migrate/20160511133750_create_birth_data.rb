class CreateBirthData < ActiveRecord::Migration[5.0]
  # - inflection for singular/plural changed in config/initializers/inflections.rb
  def change
    create_table :birth_data, id: false do |t|
      t.primary_key  :birth_dataid
      t.references   :ppatient, index: true # i.e. belongs_to (alias)

      # no other fields defined yet
    end
  end
end
