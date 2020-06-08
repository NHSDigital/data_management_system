class AddOdrNcrasDatasetsCancerRegistryAndHesv4 < ActiveRecord::Migration[6.0]
  def up
    fname = 'datasets/20191115_CancerRegistry_HES_v4.0.xlsx'
    new_dataset = OdrNcrasDatasetImporter.new('4-0', fname)
    new_dataset.build_datasets
  end
  
  def down
    # Do Nothing. please add another migration to edit or add new dataset version
  end
end
