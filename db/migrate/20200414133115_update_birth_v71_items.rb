# Align birth item names with the database
class UpdateBirthV71Items < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if dataset_version.nil?

    items = dataset_version.data_items.each_with_object([]) do |item, results|
      results << item if item.parent_table_node.name == 'birth_data'
    end

    names.each do |original, updated|
      item = items.find_all { |i| i.name == original }
      raise 'duplicate items found! something has gone wrong in a previous seed' if item.size > 1

      next if item.blank?

      item.first.update_attribute(:name, updated)
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

  def names
    {
      'fnamchx' => 'fnamchx_1',
      'loapob' => 'loarpob',
      'lsoapob' => 'lsoarpob',
      'ward9rm' => 'ward9m'
    }
  end
end
