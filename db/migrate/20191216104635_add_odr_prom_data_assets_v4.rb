class AddOdrPromDataAssetsV4 < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    fname = 'datasets/20191216_NCRAS_ODR_data_dictionary_v4.0_PROMS.xlsx'
    new_dataset = OdrNcrasDataAssetImporter.new('4-0', fname, 'odr')
    new_dataset.build_data_assets
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
