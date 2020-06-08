require 'test_helper'

class ViewDatasetsTest < ActionDispatch::IntegrationTest
  def setup
    @admin       = users(:admin_user)
    @contributor = users(:contributor)
    create_dummy_datasets
  end

  test 'user who can manager datasets can view all datasets' do
    login_and_accept_terms(@admin)
    visit datasets_path
    assert_text 'Dataset without versions'
    assert_text 'Dataset without published versions'
    assert_text 'Dataset pub version mix'
  end

  test 'user without ability cannot see datasets' do
    login_and_accept_terms(@contributor)
    visit datasets_path
    assert_no_text 'Dataset without versions'
    assert_no_text 'Dataset without published versions'
    assert_no_text 'Dataset pub version mix'
  end

  test 'user who can manager datasets has download and publish links' do
    login_and_accept_terms(@admin)
    visit dataset_version_path(@dataset_no_published_versions.dataset_versions.first)
    assert_text 'Download'
    assert_text 'Publish'
  end

  private

  def create_dummy_datasets
    @no_version_dataset = Dataset.create!(name: 'Dataset without versions',
                                          dataset_type: dataset_type(:xml),
                                          team: Team.first)
    @dataset_no_published_versions = Dataset.create!(name: 'Dataset without published versions',
                                                     dataset_type: dataset_type(:xml),
                                                     team: Team.first)
    [1, 2].each do |v|
      dv = DatasetVersion.new(semver_version: v, dataset: @dataset_no_published_versions)
      dv.nodes << version_entity_node(@dataset_no_published_versions)
      dv.save!
    end
    @dataset_published_and_unpublished_versions =
      Dataset.create!(name: 'Dataset pub version mix', dataset_type: dataset_type(:xml),
                      team: Team.first)
    [true, false].each.with_index(1) do |pub, i|
      dv = DatasetVersion.new(semver_version: i, published: pub,
                              dataset: @dataset_published_and_unpublished_versions)
      dv.nodes << version_entity_node(@dataset_published_and_unpublished_versions)
      dv.save!
    end
  end

  def version_entity_node(dataset)
    Nodes::Entity.new(name: dataset.name, min_occurs: 1)
  end
end
