class UpdateBirthWigwo9DataItem < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if dataset_version.nil?

    item = dataset_version.data_items.find_by(name: 'wigwo9')
    return if item.nil?

    item.update_attribute(:name, 'wigwo10')
  end

  def down
    # Do nothing
  end

  def dataset_version
    dataset = Dataset.find_by(name: 'MBIS')
    return if dataset.nil?

    dataset.dataset_versions.find_by(semver_version: '7.1')
  end
end
