# reseed v8 odr data assets.
class RepopulateOdrDataAssetsV8 < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    fname = 'datasets/NCRAS_ODR_data_dictionary_v8.0_KL.xlsx'
    o = OdrNcrasDataAssetImporter.new('8.0', fname, 'odr')
    o.wipe_previous_version
    o.build_data_assets
  end

  def down
    return if Rails.env.test?

    OdrNcrasDataAssetImporter.new('8.0', 'migrate', 'odr').wipe_previous_version
  end
end
