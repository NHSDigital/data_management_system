class AddMbisDatasetsToProjectTypeDataset < ActiveRecord::Migration[6.0]
  include MigrationHelper
  
  class ProjectType < ApplicationRecord
    attribute :value, :string
  end

  def change
    mbis_project_id = ProjectType.find_or_create_by!(name: 'Project').id
    mbis_datasets.each.with_index(1) do |dataset, id|
      add_lookup ProjectTypeDataset, id, project_type_id: mbis_project_id, dataset_id: dataset.id
    end
  end
  
  def mbis_datasets
    names = ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard', 'Birth Transaction']
    Dataset.where(name: names)
  end
end
