class AddMbisTableSpecs < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    importer = TableSpecImporter.new('7-0', 'datasets/MBIS_table_spec_v7-0.xlsx',
                                     'MBIS', 'MBIS', 'table_specification')
    importer.build
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
