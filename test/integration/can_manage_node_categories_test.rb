require 'test_helper'

class CanManageNodeCategoriesTest < ActionDispatch::IntegrationTest
  def setup
    login_and_accept_terms(users(:admin_user))
  end

  test 'Can update entity categories' do
    dataset = Dataset.find_by(name: 'SACT')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '2.0')

    visit dataset_version_path(dataset_version)
    assert_text 'SACT'
    assert_no_text 'View/Manage Node Categories'

    click_on 'New Node'
    click_on 'Category Choice'
    fill_in 'Name', with: 'Cat Choice'
    fill_in 'Min Occurs', with: 1
    click_on 'Save'
    assert_text('Cat Choice', count: 2)

    click_on 'Cat Choice', match: :first
    assert_text 'View/Manage Categories'

    assert_difference('Category.count', 1) do
      click_on 'View/Manage Categories'
      click_on 'Add New Category'
      fill_in 'Name', with: 'Tabby Cat'
      click_on 'Save'
      assert has_content? 'Tabby'
    end

    assert_difference('Category.count', 1) do
      click_on 'Add New Category'
      fill_in 'Name', with: 'Hell Cat'
      click_on 'Save'
      assert has_content? 'Hell'
    end

    click_on 'Back to Dataset Version'

    assert_text 'View/Manage Node Categories'
    assert_no_text 'Tabby Cat'

    assert_difference('NodeCategory.count', 2) do
      click_on 'View/Manage Node Categories'
      assert_text 'Tabby Cat'
      check "node_categories_#{dataset_version.categories.find_by(name: 'Tabby Cat').id}"
      check "node_categories_#{dataset_version.categories.find_by(name: 'Hell Cat').id}"
      click_on 'Update Node Categories'
      assert_text 'Node categories updated.'
    end

    assert_no_difference('NodeCategory.count') do
      click_on 'View/Manage Node Categories'
      assert_text 'Tabby Cat'
      uncheck "node_categories_#{dataset_version.categories.find_by(name: 'Tabby Cat').id}"
      uncheck "node_categories_#{dataset_version.categories.find_by(name: 'Hell Cat').id}"
      click_on 'Update Node Categories'
      assert_text 'Cannot remove all node_categories'
    end
  end
end
