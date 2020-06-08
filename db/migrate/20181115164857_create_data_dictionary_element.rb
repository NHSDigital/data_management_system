class CreateDataDictionaryElement < ActiveRecord::Migration[5.2]
  def change
    create_table :data_dictionary_elements do |t|
      t.string :name
      t.string :group
      t.string :status
      t.string :format_length
      t.string :national_codes
      t.string :link

      t.timestamps
    end
  end
end
