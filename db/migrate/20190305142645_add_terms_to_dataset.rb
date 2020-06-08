class AddTermsToDataset < ActiveRecord::Migration[5.2]
  def change
    add_column :datasets, :terms, :string, limit: 999
  end
end
