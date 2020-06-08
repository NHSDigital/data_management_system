# If this fails on production server, it's because a project has been made  with items from
# these datasets
class PopulateOdrNcrasDataAssetsV4 < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    Node.reset_column_information
    delete_existing
    fname = 'datasets/20191212_NCRAS_ODR_data_dictionary_v4.0.xlsx'
    new_dataset = OdrNcrasDataAssetImporter.new('4-0', fname, 'odr')
    new_dataset.build_data_assets
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def delete_existing
    ['Cancer Registry', 'Linked HES IP', 'Linked HES OP', 'Linked HES A&E'].each do |dataset_name|
      Dataset.transaction do
        dataset = Dataset.find_by(name: dataset_name)
        return unless dataset

        dataset.dataset_versions.each do |dataset_version|
          Node.where(dataset_version_id: dataset_version.id).delete_all
        end
        dataset.destroy!
      end
    end
  end
end
