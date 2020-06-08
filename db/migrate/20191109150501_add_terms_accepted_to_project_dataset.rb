class AddTermsAcceptedToProjectDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :project_datasets, :terms_accepted, :boolean
  end
end
