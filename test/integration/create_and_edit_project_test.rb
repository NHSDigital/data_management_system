require 'test_helper'

class CreateAndEditProjectTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:senior_project_user)
    @team = teams(:team_two)
    login_and_accept_terms(@user)
  end

  test 'can create a project' do
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    fill_in_project_data
    click_button 'Save'
    assert page.has_content?('Project was successfully created')

    within('#project_header') do
      assert page.has_content?('Test Project')
      assert page.has_content?('New')
    end
    end_date = (Date.current + 1.year).strftime('%d/%m/%Y')
    within('#project_summary_data_information') do
      assert page.has_content?("01/01/2018 to #{end_date}")
      assert page.has_content?('Standard2 User2')
      assert page.has_content?('This data will be used for testing')
    end

    within(class: 'project') do
      click_on 'Datasets'
    end

    within('#datasets') do
      assert has_content?('Death Transaction')
    end
  end

  test 'can create and edit a project' do
    visit team_path(teams(:team_two))

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    assert page.has_content? 'Outputs'
    assert page.has_content? 'End Uses'
    assert page.has_content? 'Level of Identifiability'
    fill_in_project_data
    click_button 'Save'
    assert page.has_content?('Project was successfully created')
    # log out and sign in with user with editing permissions
    click_on('another@phe.gov.uk')
    click_on('Logout')
    @project_user = users(:standard_user2)
    login_and_accept_terms(@project_user)
    find_link('Projects').click
    within_row('Test Project') do
      click_on 'Details'
    end
    assert page.has_no_content?('Informed Patient Consent (Mortality)')
    find_link('Legal / Ethical').click
    assert page.has_content?('Informed Patient Consent (Mortality)')
    find_link('Details').click
    find_link('Edit').click

    # accept_prompt do
    #   select 'Deaths Gold Standard', from: 'dataset_ids'
    # end

    select 'Deaths Gold Standard', from: 'project_project_datasets_attributes_0_dataset_id'
    # check('Accept Data Source Terms and Conditions')
    find_button('Save').click
    find_link('Legal / Ethical').click
    # data source is a mortality source so this should be shown
    assert page.has_content?('Informed Patient Consent (Mortality)')
    assert page.has_content?('Trackwise')

    # add some data items and trigger notices
    find_link('Data Items').click
    find_link('Add / Remove data items').click
    page.find('strong', text: 'HROPOD').click
    within('#top-buttons') do
      click_button 'Save'
    end
    assert page.has_content?('Please add a justification')
    find_link('Data Items').click
    find_link('Add / Remove data items').click
    page.find('strong', text: 'HAUTPOD').click
    within('#top-buttons') do
      click_button 'Save'
    end
    assert page.has_content?('Please add a justification')

    click_link 'Users'
    assert page.has_content? 'Download Terms & Conditions'

    # Edit the project details:
    click_on 'Details'
    click_on 'Edit'

    fill_in 'project_how_data_will_be_used', with: 'This has been changed'
    click_button 'Save'

    within('#project_summary_data_information') do
      assert page.has_content?('This has been changed')
    end

    # Add new project data source items.
    click_link 'Data Items'
    click_on 'Add / Remove data items'
    # Surame
    page.find('strong', text: 'DOB', match: :first).click
    # Date ofbirth
    page.find('strong', text: 'FNAMD2', match: :first).click
    # Non -idetifying data
    page.find('strong', text: 'GORR', match: :first).click
    within('#top-buttons') do
      click_button 'Save'
    end
    click_link 'Data Items'
    within('#project_data_items_information') do
      assert page.has_content?('FNAMD2')
      assert page.has_content?('DOB')
    end

    # Remove a Project data source item
    click_link 'Data Items'
    click_on 'Add / Remove data items'
    # Surname
    within('#selected_data_source_items') do
      page.find('strong', text: 'FNAMD2', match: :first).click
    end
    within('#top-buttons') do
      click_button 'Save'
    end
    click_link 'Data Items'
    within('#project_data_items_information') do
      assert page.has_no_content?('FNAMD2')
    end

    # Add data item justification
    %w[HROPOD HAUTPOD DOB].each do |text|
      row = page.find('tr', text: text)

      within row do
        find_link('Add Justification').evaluate_script("this.click()")
        # click_link 'Add Justification'
      end

      # This is known flakeyness location, where clicking the
      # 'Add Justification' link doesn't result in the modal.
      # I've observed this happening in Chrome, but can't figure
      # out why. Possible `row` is stale, because of this loop
      # causing bits of the to refresh? Or because there's animation
      # on the page?
      within_modal do
        assert has_content? 'Add Comment to'
        fill_in 'project_comment_text_field', with: 'I need this'
        click_button 'Save'
      end

      within row do
        assert has_text?('1 Comment')
        assert has_no_link?('Add Justification')
      end
    end

    # Attempt to destroy Senior User's membership
    click_link 'Users'

    within("#user_#{users(:standard_user2).id}") do
      assert page.has_no_content? 'Edit'
    end

    # Add a new Project membership:
    click_link 'Users'

    page.find('#project_memberships_information').click_link 'Edit'
    role_check_box =
      "grants_users_#{users(:senior_project_user).id}_#{ProjectRole.fetch(:contributor).id}"
    page.check(role_check_box)
    find_button('Update Roles').click

    within('#project_memberships_information') do
      assert page.has_content?('Another User')
    end

    # Remove a Project membership
    page.find('#project_memberships_information').click_link 'Edit'
    page.uncheck(role_check_box)
    find_button('Update Roles').click

    within('#project_memberships_information') do
      assert page.has_no_content? 'Another User'
    end

    # Submit the Batch:
    accept_prompt do
      click_button 'Submit for Delegate Approval'
    end

    # check the the project status has changed to Delegate Approval:
    within('#project_header') do
      assert page.has_content?('Delegate Approval')
    end

    # Check the correct number of versions exist of associations
    # page.find('#project_header').click_link 'Audit'
    # assert page.has_selector?('table#version-table tr', count: 11)
    # assert page.has_content?('Project membership', count: 2)
    # assert page.has_content?('Project node', count: 5)
  end

  # TODO: Fix this. JS no longer works
  test 'project with death datasource shows extra fields' do
    skip
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    fill_in_project_data
    assert page.has_no_content?('Legal gateway to Process ONS mortality data')
    new_dataset.find(:option, 'Births Gold Standard').select_option
    # select 'Births Gold Standard', from: 'project_project_datasets_attributes_0_dataset_id'
    assert page.has_no_content?('Legal gateway to Process ONS mortality data')
    new_dataset.find(:option, 'Death Transaction').select_option
    # check 'Death Transaction'
    assert page.has_content?('Legal gateway to Process ONS mortality data')
  end

  # senior_project_user => Another User (signed in)
  # standard_user2      => Standard2 User2
  test 'only owner grant is created when a user creates and owns a project' do
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    fill_in_project_data
    fill_in 'project_name', with: 'user creating is project owner'
    select 'Another User', from: 'project_owner_grant_attributes_user_id'
    assert_difference('Grant.count', 1) do
      click_button 'Save'
    end
    project = Project.find_by(name: 'user creating is project owner')
    assert page.has_content?('Project was successfully created')
    assert project.grants.first.roleable == ProjectRole.fetch(:owner)
  end

  # senior_project_user => Another User (signed in)
  # standard_user2      => Standard2 User2
  test 'correct grants assigned when user creating project for another user' do
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    fill_in_project_data
    fill_in 'project_name', with: 'user is creating project for another user'
    assert_difference('Grant.count', 2) do
      click_button 'Save'
    end
    project = Project.find_by(name: 'user is creating project for another user')
    assert_equal 1, (project.grants.count { |g| g.roleable == owner_role })
    assert_equal 1, (project.grants.count { |g| g.roleable == contributor_role })
    assert users(:standard_user2) == project.grants.find_by(roleable: owner_role).user
    assert users(:senior_project_user) == project.grants.find_by(roleable: contributor_role).user
    assert page.has_content?('Project was successfully created')
  end

  # senior_project_user => Another User (signed in)
  # standard_user2      => Standard2 User2
  test 'changing owner reassigns grants' do
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end

    fill_in_project_data
    fill_in 'project_name', with: 'created for someone else in team'
    assert_difference('Grant.count', 2) do
      click_button 'Save'
    end
    project = Project.find_by(name: 'created for someone else in team')
    owner_grant_id = project.owner_grant.id

    assert_equal 1, (project.grants.count { |g| g.roleable == owner_role })
    assert_equal 1, (project.grants.count { |g| g.roleable == contributor_role })
    assert users(:standard_user2) == project.grants.find_by(roleable: owner_role).user
    assert users(:senior_project_user) == project.grants.find_by(roleable: contributor_role).user
    assert page.has_content?('Project was successfully created')

    click_on('another@phe.gov.uk')
    click_on('Logout')
    assert page.has_content? 'Signed out successfully.'

    login_and_accept_terms(users(:standard_user2))

    visit project_path(project)
    find_link('Details').click
    find_link('Edit').click
    select 'Another User', from: 'project_owner_grant_attributes_user_id'
    assert_difference('Grant.count', 0) do
      click_button 'Save'
    end
    assert users(:senior_project_user) == project.grants.find_by(roleable: owner_role).user
    assert users(:standard_user2) == project.grants.find_by(roleable: contributor_role).user
    # owner_grant was edited
    project.reload
    assert_equal owner_grant_id, project.owner_grant.id
  end

  test 'can remove an extra dataset and submit' do
    visit team_path(@team)

    within('#projects-panel') do
      click_button 'New'
      click_link 'Project'
    end
    fill_in 'project_name', with: 'Dataset Project Test'
    fill_in 'project_start_data_date', with: '01/01/2018'
    fill_in 'project_end_data_date', with: (Date.current + 1.year).strftime('%d/%m/%Y)')

    # select a dataset
    select_and_accept_new_dataset('Death Transaction')
    # select another dataset but change mind and remove it
    new_li = find_new('li') do
      click_on 'Add Dataset'
    end
    new_li.find('div.remove_record').click
    assert_difference('ProjectDataset.count', 1) do
      click_button 'Save'
    end
  end

  test 'users full name appears correctly on project users screen' do
    project = @user.projects.first
    visit project_path(project)
    click_on 'Users'

    # Check Project Users Grants
    project.users.each do |user|
      assert has_content? user.full_name
    end

    # Check Edit screen
    project.grants.without_project_owner.each do |user|
      assert has_content? user.full_name
    end
  end

  private

  def fill_in_project_data
    fill_in 'project_name', with: 'Test Project'
    select_and_accept_new_dataset('Death Transaction')

    fill_in 'project_start_data_date', with: '01/01/2018'
    fill_in 'project_end_data_date', with: (Date.current + 1.year).strftime('%d/%m/%Y)')
    fill_in 'project_how_data_will_be_used', with: 'This data will be used for testing'
    select 'Standard2 User2', from: 'project_owner_grant_attributes_user_id'
    select 'Weekly', from: 'project_frequency'
    # End uses
    check('Research')
    check('Service Evaluation')
    # Outputs
    select 'Anonymous', from: 'project_level_of_identifiability'
  end

  def owner_role
    ProjectRole.fetch(:owner)
  end

  def contributor_role
    ProjectRole.fetch(:contributor)
  end
end
