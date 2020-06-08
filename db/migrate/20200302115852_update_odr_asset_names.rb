class UpdateOdrAssetNames < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    datasets.each do |old_name, new_name|
      ds = Dataset.find_by(name: old_name, dataset_type_id: DatasetType.find_by(name: 'odr').id)
      ds.name = new_name
      ds.full_name = new_name
      ds.save!
    end
  end

  def down
    return if Rails.env.test?

    datasets.each do |old_name, new_name|
      ds = Dataset.find_by(name: new_name, dataset_type_id: DatasetType.find_by(name: 'odr').id)
      ds.name = old_name
      ds.full_name = old_name
      ds.save!
    end
  end

  def datasets
    {
      'Linked CWT' => 'Linked CWT (treatments only)', 
      'Linked HES IP' =>'Linked HES Admitted Care (IP)'
    }
  end
end
