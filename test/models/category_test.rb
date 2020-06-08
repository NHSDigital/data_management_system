require 'test_helper'
class CategoryTest < ActiveSupport::TestCase
  test 'only one instance of a category per version' do
    dataset_version = DatasetVersion.find_by(semver_version: '9.0')
    existing_category = Category.where(dataset_version: dataset_version).first
    category_with_same_name =
      Category.new(dataset_version: Category.first.dataset_version, name: existing_category.name)
    refute category_with_same_name.valid?
    assert category_with_same_name.errors.messages[:name].present?
    assert category_with_same_name.errors.messages[:name].include? 'One occurrence per version'
  end
end
