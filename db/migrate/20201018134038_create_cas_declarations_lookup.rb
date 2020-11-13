class CreateCasDeclarationsLookup < ActiveRecord::Migration[6.0]
  def change
    create_table :cas_declarations do |t|
      t.text 'value'
      t.integer 'sort'
    end
  end
end
