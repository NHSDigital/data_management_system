include MigrationHelper
class PopulateClassifications < ActiveRecord::Migration[5.0]
  # def change
  #   add_lookup Classification, '1', name: 'Anonymised'
  #   add_lookup Classification, '2', name: 'potentially identifiable'
  #   add_lookup Classification, '3', name: 'identifiable'
  # end

  # def down
  #   query = <<-SQL
  #   DELETE FROM CLASSIFICATIONS
  #   SQL
  #   execute(query)
  # end

  def up
    Classification.create!(name: 'Anonymised')
    Classification.create!(name: 'potentially identifiable')
    Classification.create!(name: 'identifiable')
  end

  def down
    Classification.find_by_name('Anonymised').destroy
    Classification.find_by_name('potentially identifiable').destroy
    Classification.find_by_name('identifiable').destroy
  end
end
