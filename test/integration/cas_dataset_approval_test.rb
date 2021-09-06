require 'test_helper'

class CasDatasetApprovalTest < ActionDispatch::IntegrationTest
  test 'should be able to approve and reject datasets' do
    user = users(:cas_dataset_approver)
    ProjectDatasetLevelsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)
    sign_in user

    project = create_cas_project(owner: users(:standard_user2))
    dataset = Dataset.find_by(name: 'Extra CAS Dataset One')
    pd = ProjectDataset.create(dataset: dataset, terms_accepted: true)
    project.project_datasets << pd
    pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                     project_dataset_id: pd.id)
    ProjectDatasetLevel.create(access_level_id: 2, expiry_date: Time.zone.today + 2.weeks,
                               project_dataset_id: pd.id)

    project.transition_to!(workflow_states(:submitted))
    visit cas_approvals_projects_path

    within '#my_dataset_approvals' do
      assert has_content?(project.id.to_s)
      click_link(href: "/projects/#{project.id}#!datasets", title: 'Details')
    end

    within '#requested_project_dataset_levels_table' do
      assert has_content?('Extra CAS Dataset One', count: 2)
    end

    assert_equal 'request', pdl.status_id

    assert_changes -> { pdl.reload.status_id }, from: 'request', to: 'approved' do
      find("#approval_project_dataset_level_#{pdl.id}").click
      within_modal(selector: '#yubikey-challenge') do
        fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
        click_button 'Submit'
      end
      within '#approved_project_dataset_levels_table' do
        within "#project_dataset_level_#{pdl.id}" do
          within '#decision_date' do
            assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
          end
          assert has_content?('APPROVED')
        end
      end
    end

    within '#requested_project_dataset_levels_table' do
      assert has_content?('Extra CAS Dataset One', count: 1)
    end

    assert_equal find('#project_status').text, 'Pending'

    pdl.update(status_id: 1, decided_at: nil)

    visit project_path(project)
    click_link(href: '#datasets')

    within '#requested_project_dataset_levels_table' do
      assert has_content?('Extra CAS Dataset One', count: 2)
    end

    assert_changes -> { pdl.reload.status_id }, from: 'request', to: 'rejected' do
      within "#approvals_project_dataset_level_#{pdl.id}" do
        find('.btn-danger').click
      end
      within '#rejected_project_dataset_levels_table' do
        within "#project_dataset_level_#{pdl.id}" do
          within '#decision_date' do
            assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
          end
          assert has_content?('DECLINED')
        end
      end
    end

    assert_equal find('#project_status').text, 'Pending'
  end

  test 'should be able to reapply for a dataset if approval declined' do
    user = users(:no_roles)
    sign_in user

    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.new(dataset: dataset(86), terms_accepted: true)
    project.project_datasets << project_dataset
    l1_pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 2.months,
                                        selected: true, project_dataset_id: project_dataset.id)
    l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, expiry_date: Time.zone.today + 2.months,
                                        selected: true, project_dataset_id: project_dataset.id)

    project.transition_to!(workflow_states(:submitted))

    l1_pdl.update(status_id: 2, decided_at: Time.zone.now)
    l2_pdl.update(status_id: 2, decided_at: Time.zone.now)

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Cas Defaults Dataset', count: 2)
    assert has_content?('APPROVED', count: 2)
    assert has_no_button?('Reapply')

    l1_pdl.update(status_id: 3, decided_at: Time.zone.now)
    l2_pdl.update(status_id: 3, decided_at: Time.zone.now)

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Cas Defaults Dataset', count: 2)

    assert has_content?('DECLINED', count: 2)

    within "#project_dataset_level_#{l2_pdl.id}" do
      click_button('Reapply')
    end

    assert_equal 2, ProjectDatasetLevel.last.reload.access_level_id
    assert has_content?('Rejected datasets')
    assert has_content?('Reapplication request created succesfully')

    within "#project_dataset_level_#{ProjectDatasetLevel.last.id}" do
      within '#request_type' do
        assert has_content?('Reapplication')
      end
      assert has_content?('PENDING')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Reapply')
    end

    within "#project_dataset_level_#{l2_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('DECLINED')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Reapply')
    end

    assert_equal 'rejected', l2_pdl.reload.status_id
    assert_equal 'request', ProjectDatasetLevel.last.reload.status_id

    within "#project_dataset_level_#{l1_pdl.id}" do
      click_button('Reapply')
    end

    within_modal(selector: '#modal-reapply') do
      assert has_content?('Reapplication for Cas Defaults Dataset level 1')
      fill_in('reapply_datepicker', with: '')
      click_button('Save')
    end

    assert has_content?('Reapplication failed - please provide a valid expiry date in the future')
    assert has_button?('Reapply')
    assert_equal 2, ProjectDatasetLevel.last.reload.access_level_id

    within "#project_dataset_level_#{l1_pdl.id}" do
      click_button('Reapply')
    end

    within_modal(selector: '#modal-reapply') do
      fill_in('reapply_datepicker', with: (Time.zone.now + 1.year).strftime('%d/%m/%Y)'))
      click_button('Save')
    end

    assert has_content?('Reapplication request created succesfully')
    assert has_no_button?('Reapply')
    l1_reapplication = ProjectDatasetLevel.last
    assert_equal 1, l1_reapplication.reload.access_level_id

    within "#project_dataset_level_#{l1_reapplication.id}" do
      within '#request_type' do
        assert has_content?('Reapplication')
      end
      assert has_content?('PENDING')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Reapply')
    end

    within "#project_dataset_level_#{l1_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('DECLINED')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Reapply')
    end

    assert_equal 'rejected', l1_pdl.reload.status_id
    assert_equal 'request', l1_reapplication.reload.status_id

    l1_reapplication.update(status_id: 3)

    visit project_path(project)
    click_link(href: '#datasets')

    within "#project_dataset_level_#{l1_reapplication.id}" do
      assert has_button?('Reapply')
    end

    within "#project_dataset_level_#{l1_pdl.id}" do
      assert has_no_button?('Reapply')
    end
  end

  test 'should be able to apply for renewal of a dataset if within expiry period' do
    user = users(:no_roles)
    sign_in user

    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.new(dataset: dataset(86), terms_accepted: true)
    project.project_datasets << project_dataset
    l1_pdl = ProjectDatasetLevel.create(access_level_id: 1, expiry_date: Time.zone.today + 1.week,
                                        selected: true, project_dataset_id: project_dataset.id)
    l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, expiry_date: Time.zone.today + 1.week,
                                        selected: true, project_dataset_id: project_dataset.id)

    project.transition_to!(workflow_states(:submitted))

    l1_pdl.update(status_id: 2, decided_at: Time.zone.now)
    l2_pdl.update(status_id: 2, decided_at: Time.zone.now)

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Cas Defaults Dataset', count: 2)
    assert has_content?('APPROVED', count: 2)
    assert has_no_button?('Renew')

    l1_pdl.update(status_id: 4)
    l2_pdl.update(status_id: 4)

    visit project_path(project)

    click_link(href: '#datasets')
    assert has_content?('Cas Defaults Dataset')
    assert has_content?('Approved datasets')
    assert has_no_content?('Requested datasets')
    within "#project_dataset_level_#{l2_pdl.id}" do
      click_button('Renew')
    end

    assert has_content?('Requested datasets')
    assert has_content?('Renewal request created succesfully')
    assert_equal 2, ProjectDatasetLevel.last.reload.access_level_id
    within '#requested_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 1)
    end
    within '#approved_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 2)
    end

    within "#project_dataset_level_#{ProjectDatasetLevel.last.id}" do
      within '#request_type' do
        assert has_content?('Renewal')
      end
      assert has_content?('PENDING')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Renew')
    end

    within "#project_dataset_level_#{l2_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('APPROVED')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Renew')
    end

    assert_equal 'approved', l2_pdl.reload.status_id
    assert_equal 'request', ProjectDatasetLevel.last.reload.status_id

    within "#project_dataset_level_#{l1_pdl.id}" do
      click_button('Renew')
    end

    within_modal(selector: '#modal-renewal') do
      assert has_content?('Renewal for Cas Defaults Dataset level 1')
      fill_in('renewal_datepicker', with: '')
      click_button('Save')
    end

    within '#requested_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 1)
    end
    within '#approved_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 2)
    end

    assert has_content?('Renewal failed - please provide a valid expiry date in the future')
    assert has_button?('Renew')
    assert_equal 2, ProjectDatasetLevel.last.reload.access_level_id

    within "#project_dataset_level_#{l1_pdl.id}" do
      click_button('Renew')
    end

    within_modal(selector: '#modal-renewal') do
      fill_in('renewal_datepicker', with: (Time.zone.now + 1.year).strftime('%d/%m/%Y)'))
      click_button('Save')
    end

    within '#requested_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 2)
    end
    within '#approved_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 2)
    end

    assert has_content?('Renewal request created succesfully')
    assert_equal 1, ProjectDatasetLevel.last.reload.access_level_id

    within "#project_dataset_level_#{ProjectDatasetLevel.last.id}" do
      within '#request_type' do
        assert has_content?('Renewal')
      end
      assert has_content?('PENDING')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Renew')
    end

    within "#project_dataset_level_#{l1_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('APPROVED')
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert has_no_button?('Renew')
    end

    assert_equal 'approved', l1_pdl.reload.status_id
    assert_equal 'request', ProjectDatasetLevel.last.reload.status_id

    sign_out user
    sign_in users(:cas_access_and_dataset_approver)

    visit project_path(project)
    click_link(href: '#datasets')

    ProjectDatasetLevelsController.any_instance.expects(:valid_otp?).twice.returns(false).then.returns(true)
    find("#approval_project_dataset_level_#{ProjectDatasetLevel.last.id}").click
    within_modal(selector: '#yubikey-challenge') do
      fill_in 'ndr_authenticate[otp]', with: 'defo a yubikey'
      click_button 'Submit'
    end

    assert_equal 'closed', l1_pdl.reload.status_id
    assert_equal 'approved', ProjectDatasetLevel.last.reload.status_id
  end

  test 'should show applicant correct pending dataset status' do
    # Other statuses are covered in the test above
    user = users(:no_roles)
    sign_in user

    project = create_cas_project(owner: users(:no_roles))
    project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                         terms_accepted: nil)
    project.project_datasets << project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week)
    project_dataset.project_dataset_levels << pdl

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)
    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')
    assert_equal find('#dataset_level_status').text, 'PENDING'
    within '#request_type' do
      assert has_content?('New')
    end
  end

  test 'should show cas_dataset approver correct dataset statuses' do
    user = users(:cas_dataset_approver)
    sign_in user

    project = create_cas_project(owner: users(:standard_user2))
    grant_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset One'),
                                       terms_accepted: true)
    non_grant_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Extra CAS Dataset Two'),
                                           terms_accepted: true)
    project.project_datasets << grant_dataset
    project.project_datasets << non_grant_dataset
    grant_pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week)
    non_grant_pdl = ProjectDatasetLevel.new(access_level_id: 1, expiry_date: Time.zone.today + 1.week)
    grant_dataset.project_dataset_levels << grant_pdl
    non_grant_dataset.project_dataset_levels << non_grant_pdl

    project.transition_to!(workflow_states(:submitted))

    visit project_path(project)
    click_link(href: '#datasets')
    assert has_content?('Extra CAS Dataset One')
    assert has_content?('Extra CAS Dataset Two')

    within("#project_dataset_level_#{grant_pdl.id}") do
      assert has_css?('.btn-danger')
      assert has_css?('.btn-success')
      assert has_no_content?('PENDING')
      within '#request_type' do
        assert has_content?('New')
      end
    end

    within("#project_dataset_level_#{non_grant_pdl.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_level_status').text, 'PENDING'
      within '#request_type' do
        assert has_content?('New')
      end
    end

    non_grant_pdl.status_id = 2
    non_grant_pdl.save!(validate: false)

    visit project_path(project)

    click_link(href: '#datasets')

    within("#project_dataset_level_#{non_grant_pdl.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_level_status').text, 'APPROVED'
    end

    non_grant_pdl.status_id = 3
    non_grant_pdl.save!(validate: false)

    visit project_path(project)

    click_link(href: '#datasets')

    within("#project_dataset_level_#{non_grant_pdl.id}") do
      assert has_no_css?('.btn-danger')
      assert has_no_css?('.btn-success')
      assert_equal find('#dataset_level_status').text, 'DECLINED'
    end
  end

  test 'bulk approve button and highlighting of pending datasets should behave correctly' do
    project = create_cas_project(owner: users(:standard_user2))
    grant_default_dataset = ProjectDataset.new(dataset: dataset(86), terms_accepted: true)
    nogrant_extra_dataset = ProjectDataset.new(dataset: dataset(84), terms_accepted: true)
    project.project_datasets.push(grant_default_dataset, nogrant_extra_dataset)
    rejected_default_l1_pdl = ProjectDatasetLevel.new(access_level_id: 1, selected: true,
                                                      expiry_date: Time.zone.today + 1.week)
    grant_default_l1_pdl = ProjectDatasetLevel.new(access_level_id: 1, selected: true,
                                                   expiry_date: Time.zone.today + 1.week)
    grant_default_l2_pdl = ProjectDatasetLevel.new(access_level_id: 2, selected: true,
                                                   expiry_date: Time.zone.today + 1.year)
    grant_default_l3_pdl = ProjectDatasetLevel.new(access_level_id: 3, selected: true,
                                                   expiry_date: Time.zone.today + 1.year)
    no_grant_extra_l2_pdl = ProjectDatasetLevel.new(access_level_id: 2, selected: true,
                                                    expiry_date: Time.zone.today + 1.year)
    grant_default_dataset.project_dataset_levels.push(rejected_default_l1_pdl, grant_default_l1_pdl,
                                                      grant_default_l2_pdl, grant_default_l3_pdl)
    nogrant_extra_dataset.project_dataset_levels << no_grant_extra_l2_pdl

    rejected_default_l1_pdl.update(status_id: 3, decided_at: Time.zone.now - 1.day)

    project.transition_to!(workflow_states(:submitted))

    sign_in users(:standard_user2)

    visit project_path(project)
    click_link(href: '#datasets')
    within '#requested_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 3)
      assert has_content?('Extra CAS Dataset Two', count: 1)
    end
    within '#rejected_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 1)
    end
    assert has_no_content?('Approve level 2 and 3 default datasets')

    assert find("#project_dataset_level_#{rejected_default_l1_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l1_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l2_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l3_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{no_grant_extra_l2_pdl.id}")[:class].
      exclude?('dataset_highlight')

    sign_out users(:standard_user2)
    sign_in users(:cas_access_and_dataset_approver)

    visit project_path(project)
    click_link(href: '#datasets')
    within '#requested_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 3)
      assert has_content?('Extra CAS Dataset Two', count: 1)
    end
    within '#rejected_project_dataset_levels_table' do
      assert has_content?('Cas Defaults Dataset', count: 1)
    end
    assert has_button?('Approve level 2 and 3 default datasets')

    assert find("#project_dataset_level_#{rejected_default_l1_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l1_pdl.id}")[:class].
      include?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l2_pdl.id}")[:class].
      include?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l3_pdl.id}")[:class].
      include?('dataset_highlight')
    assert find("#project_dataset_level_#{no_grant_extra_l2_pdl.id}")[:class].
      exclude?('dataset_highlight')

    assert_equal 'rejected', rejected_default_l1_pdl.reload.status_id
    assert_equal 'request', grant_default_l1_pdl.reload.status_id
    assert_equal 'request', grant_default_l2_pdl.reload.status_id
    assert_equal 'request', grant_default_l3_pdl.reload.status_id
    assert_equal 'request', no_grant_extra_l2_pdl.reload.status_id

    click_button('Approve level 2 and 3 default datasets')

    assert has_no_button?('Approve level 2 and 3 default datasets')

    within "#project_dataset_level_#{rejected_default_l1_pdl.id}" do
      within '#decision_date' do
        assert has_content?((Time.zone.now - 1.day).strftime('%d/%m/%Y'))
      end
      assert has_content?('DECLINED')
    end

    within "#project_dataset_level_#{grant_default_l1_pdl.id}" do
      within '#request_type' do
        # because there has already been a rejected default l1
        assert has_content?('Reapplication')
      end
      assert find('.btn-danger')
      assert find('.btn-success')
      assert has_no_content?('APPROVED')
    end

    within "#project_dataset_level_#{grant_default_l2_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('APPROVED')
    end

    within "#project_dataset_level_#{grant_default_l3_pdl.id}" do
      within '#decision_date' do
        assert has_content?(Time.zone.now.strftime('%d/%m/%Y'))
      end
      assert has_content?('APPROVED')
    end

    within "#project_dataset_level_#{no_grant_extra_l2_pdl.id}" do
      within '#request_type' do
        assert has_content?('New')
      end
      assert has_content?('PENDING')
    end

    assert find("#project_dataset_level_#{rejected_default_l1_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l1_pdl.id}")[:class].
      include?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l2_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{grant_default_l3_pdl.id}")[:class].
      exclude?('dataset_highlight')
    assert find("#project_dataset_level_#{no_grant_extra_l2_pdl.id}")[:class].
      exclude?('dataset_highlight')

    assert_equal 'rejected', rejected_default_l1_pdl.reload.status_id
    assert_equal 'request', grant_default_l1_pdl.reload.status_id
    assert_equal 'approved', grant_default_l2_pdl.reload.status_id
    assert_equal 'approved', grant_default_l3_pdl.reload.status_id
    assert_equal 'request', no_grant_extra_l2_pdl.reload.status_id

    assert has_no_content?('Approve Access')

    # make decision on final default dataset
    within "#project_dataset_level_#{grant_default_l1_pdl.id}" do
      find('.btn-danger').click
    end

    assert has_content?('Approve Access')
  end

  test 'ensure expired project_dataset_levels display in closed table' do
    project = create_cas_project(owner: users(:standard_user2))
    default_dataset = ProjectDataset.create(dataset: dataset(86), terms_accepted: true)
    project.project_datasets << default_dataset
    default_l2_pdl = ProjectDatasetLevel.create(access_level_id: 2, selected: true,
                                                decided_at: Time.zone.today - 1.year,
                                                project_dataset_id: default_dataset.id)

    default_l2_pdl.status_id = 5
    default_l2_pdl.expiry_date = Time.zone.today - 1.week
    default_l2_pdl.save!(validate: false)

    user = users(:standard_user2)
    sign_in user

    visit project_path(project)
    click_link(href: '#datasets')
    within '#closed_project_dataset_levels_table' do
      within "#project_dataset_level_#{default_l2_pdl.id}" do
        within '#decision_date' do
          assert has_content?((Time.zone.now - 1.year).strftime('%d/%m/%Y'))
        end
        assert has_content?('CLOSED')
      end
    end
  end
end
