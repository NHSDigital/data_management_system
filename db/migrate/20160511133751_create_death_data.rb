class CreateDeathData < ActiveRecord::Migration[5.0]
  # - inflection for singular/plural changed in config/initializers/inflections.rb
  def change
    create_table :death_data, id: false do |t|
      t.primary_key  :death_dataid
      t.references   :ppatient, index: true # i.e. belongs_to (alias)

      # no other fields defined yet
    end
  end
end
