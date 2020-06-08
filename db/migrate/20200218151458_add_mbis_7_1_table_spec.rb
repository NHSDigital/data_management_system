class AddMbis71TableSpec < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    importer = TableSpecImporter.new('7.1', 'datasets/MBIS_table_spec_v7-1.xlsx',
                                     'MBIS', 'MBIS', 'table_specification')
    importer.build
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
