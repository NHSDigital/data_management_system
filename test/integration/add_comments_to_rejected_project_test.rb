require 'test_helper'
require 'project_helper'

class AddCommentsToRejectedProjectTest < ActionDispatch::IntegrationTest
  test 'normal user can not edit when project in approved state' do
    login_and_accept_terms(users(:rejected_standard_user))
    visit project_path(projects(:rejected_project))
    click_link('Details')
    # page.find('#project_summary_data_information').click_on('1 Comment')
    page.find('#project_summary_data_information').find_link('1 Comment').click
    find('#project_summary_data_information').find_link('Add comment').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'I think they are all good'
      click_button 'Save'
    end
    assert has_no_selector?('#modal', visible: true)
    assert_equal 4, ProjectComment.all.count
    click_link('Data Items')
    page.find('#project_data_items_information').click_on('1 Comment', match: :first)
    find('#project_data_items_information').find_link('Add comment').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'I really want this data item'
      click_button 'Save'
    end
    assert has_no_selector?('#modal', visible: true)
    assert_equal 5, ProjectComment.all.count
    click_link('Users')
    page.find('#project_memberships_information').click_on('1 Comment')
    find('#project_memberships_information').find_link('Add comment').click
    within_modal do
      fill_in 'project_comment_text_field', with: 'I think Bob is alright'
      click_button 'Save'
    end
    assert has_no_selector?('#modal', visible: true)
    assert_equal 6, ProjectComment.all.count

    click_link('Details')
    # page.find('#project_summary_data_information').click_on('2 Comments')
    page.find('#project_summary_data_information').find_link('2 Comments').click
    assert page.has_content?('I think they are all good')
    assert page.has_no_content?('I think Bob is alright')

    click_link('Data Items')
    page.find('#project_data_items_information').click_on('2 Comments', match: :first)
    assert page.has_content?('I really want this data item')
    assert page.has_no_content?('I think Bob is alright')

    click_link('Users')
    # page.find('#project_memberships_information').click_on('2 Comments')

    assert page.has_no_content?('I think they are all good')
    assert page.has_content?('I think Bob is alright')
  end

  test 'can delete a data source item with comments' do
    skip
    
    login_and_accept_terms(users(:rejected_senior_user))
    visit project_path(projects(:rejected_project))
    assert_equal 3, ProjectComment.all.count
    click_link('Data Items')
    click_on 'Add / Remove data items'
    # Surname
    page.find('#data_source_item_dateofbirth').click
    within('#bottom-buttons') do
      click_button 'Save'
    end
    assert_equal 2, ProjectComment.all.count
  end
end
