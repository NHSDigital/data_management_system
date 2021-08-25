require 'test_helper'

class ReleasesTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:application_manager_one)
  end

  test 'should be able to view the list of releases' do
    project = projects(:test_application)
    release = create_release(project)

    visit project_path(project)
    click_on('Releases')

    dom_id = "\#release_#{release.id}"

    assert has_link?(href: new_project_release_path(project))
    assert has_selector?(dom_id)

    within(dom_id) do
      assert has_link?(href: release_path(release),      title: 'Details')
      assert has_link?(href: edit_release_path(release), title: 'Edit')
      assert has_link?(href: release_path(release),      title: 'Delete')
    end
  end

  test 'should be able to create a release' do
    project = projects(:test_application)

    visit project_path(project)
    click_on('Releases')

    click_link('New')

    select  project.reference,                     from: 'Associated With'
    fill_in 'release[invoice_requested_date]',     with: '15/04/2020'
    fill_in 'release[invoice_sent_date]',          with: '15/04/2020'
    fill_in 'release[phe_invoice_number]',         with: 'PHE-1234'
    fill_in 'release[po_number]',                  with: 'PO-2345'
    fill_in 'release[ndg_opt_out_processed_date]', with: '15/04/2020'
    fill_in 'release[cprd_reference]',             with: 'CPRD-3456'
    fill_in 'release[actual_cost]',                with: 1000.00
    select  'Not Applicable',                      from: 'release[vat_reg]'
    select  'No',                                  from: 'release[income_received]'
    fill_in 'release[drr_no]',                     with: 'DRR-4567'
    select  'No',                                  from: 'release[cost_recovery_applied]'
    fill_in 'release[individual_to_release]',      with: 'Yogi Bear'
    fill_in 'release[release_date]',               with: '15/04/2020'

    assert_difference -> { project.global_releases.count } do
      assert_difference -> { project.releases.count } do
        click_button('Create Release')

        assert_equal project_path(project), current_path
        assert has_text?('Release created successfully')
        assert has_selector?('#releasesTable', visible: true)
      end
    end
  end

  test 'should be able to update a release' do
    project = projects(:test_application)
    release = create_release(project)

    visit project_path(project)
    click_on('Releases')

    click_link(href: edit_release_path(release))

    select  'Yes',                            from: 'release[income_received]'
    fill_in 'release[individual_to_release]', with: 'Yogi Bear'
    fill_in 'release[release_date]',          with: Time.zone.today.to_s(:ui)

    assert_changes -> { release.reload.release_date } do
      click_button('Update Release')

      assert_equal project_path(project), current_path
      assert has_text?('Release updated successfully')
      assert has_selector?('#releasesTable', visible: true)
    end
  end

  test 'should be able to destroy a release' do
    project = projects(:test_application)
    release = create_release(project)

    visit project_path(project)
    click_on('Releases')

    assert_difference -> { project.global_releases.count }, -1 do
      assert_difference -> { project.releases.count }, -1 do
        accept_prompt do
          click_link(href: release_path(release), title: 'Delete')
        end

        assert_equal project_path(project), current_path
        assert has_selector?('#releasesTable', visible: true)
      end
    end

    assert has_text?('Release destroyed successfully')
  end

  test 'should be able to view a release' do
    project = projects(:test_application)
    release = create_release(project)

    visit project_path(project)
    click_on('Releases')

    click_link(href: release_path(release), title: 'Details')
    assert_equal release_path(release), current_path
  end

  test 'should redirect if unauthorized' do
    sign_out users(:application_manager_one)
    sign_in  users(:standard_user)

    project = projects(:test_application)
    release = create_release(project)

    visit edit_release_path(release)

    refute_equal edit_release_path(release), current_path
    assert has_text?('You are not authorized to access this page.')
  end
end
