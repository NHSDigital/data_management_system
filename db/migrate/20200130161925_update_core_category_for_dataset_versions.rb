class UpdateCoreCategoryForDatasetVersions < ActiveRecord::Migration[6.0]
  def up
    Category.where(name: 'Other').update_all(core: true)
  end

  def down
    Category.where(name: 'Other').update_all(core: false)
  end
end
