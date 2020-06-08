# Has many through for Project Type Datasets
class ProjectTypeDataset < ApplicationRecord
  belongs_to :project_type, inverse_of: :project_type_datasets
  belongs_to :dataset
end
