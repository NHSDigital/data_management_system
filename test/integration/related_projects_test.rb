require 'test_helper'

class RelatedProjectsTest < ActionDispatch::IntegrationTest
  test 'should be able to see linked projects' do
    user = users(:standard_user)

    project                    = projects(:one)
    directly_related_project   = projects(:test_application)
    indirectly_related_project = projects(:two)
    other_project              = projects(:dummy_project)

    # Ensure user has visibility of these...
    [project, directly_related_project, indirectly_related_project].each do |resource|
      resource.grants.create!(user: user, roleable: project_roles(:contributor))
    end

    # Ensure projects are sufficiently related...
    directly_related_project.left_relationships.create!(right_project: indirectly_related_project)

    sign_in user

    visit project_path(project)

    click_link('Related')

    within('#related') do
      assert has_text?(directly_related_project.name)
      assert has_link?(href: project_path(directly_related_project))

      assert has_text?(indirectly_related_project.name)
      assert has_link?(href: project_path(indirectly_related_project))

      # `other_project` is related through :test_application (see fixtures) but user has no
      # grant so shouldn't see it...
      assert has_no_text?(other_project.name)
      assert has_no_link?(href: project_path(other_project))
    end
  end

  test 'should not be able to modify project linkages unless authorized' do
    project = projects(:test_application)

    sign_in users(:standard_user)

    visit project_path(project)

    click_link 'Related'

    within('#related') do
      assert has_no_link?(href: project_project_relationships_path(project))
    end

    visit project_project_relationships_path(project)

    assert_equal root_path, current_path
    assert has_text?(/not authorized/)
  end

  test 'should be able to add and remove links between projects' do
    project = projects(:test_application)
    other   = projects(:dummy_project)

    sign_in users(:application_manager_one)

    visit project_path(project)

    click_link 'Related'

    within('#related') do
      click_link href: project_project_relationships_path(project)
    end

    assert has_link?(href: project_path(project, anchor: '!related'))
    assert has_selector?('form#project_search_form', visible: :all)

    assert_difference -> { project.related_projects.count }, -1 do
      within("tr#project_#{other.id}") do
        accept_prompt { click_link 'Remove' }

        assert has_no_link?('Remove')
        assert has_button?('Add')
      end
    end

    assert_difference -> { project.related_projects.count } do
      within("tr#project_#{other.id}") do
        click_button 'Add'

        assert has_link?('Remove')
        assert has_no_button?('Add')
      end
    end
  end
end
