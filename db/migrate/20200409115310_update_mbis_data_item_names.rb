# clean up node names imported from excel
class UpdateMbisDataItemNames < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if dataset_version.nil?

    items_to_update = dataset_version.data_items.find_all { |di| di.name.match?(/[[:space:]]/) }
    items_to_update.each do |item|
      item.update_attribute(:name, item.name.squish)
    end
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
