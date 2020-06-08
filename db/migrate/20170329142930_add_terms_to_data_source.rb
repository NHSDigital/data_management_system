class AddTermsToDataSource < ActiveRecord::Migration[5.0]
  def change
    add_column :data_sources, :terms, :text
  end
end
