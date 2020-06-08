# to handle ODR 'data assets'
class AddOdrDatasetType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup DatasetType, 4, name: 'odr'
  end
end
