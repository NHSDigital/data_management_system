require 'test_helper'

class ProjectDatasetTest < ActiveSupport::TestCase
  test 'Only unique datasets allowed' do
    project = build_project
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    project_dataset = ProjectDataset.new(dataset: dataset)
    project.project_datasets << project_dataset
    project.project_datasets << project_dataset
    refute project.valid?
  end
end
