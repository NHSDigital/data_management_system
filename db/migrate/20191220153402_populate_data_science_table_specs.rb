class PopulateDataScienceTableSpecs < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?    

    importer = DataScienceImporter.new('1-0', 'TechnicalGuideContent.xlsx')
    importer.build
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
