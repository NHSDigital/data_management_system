require 'test_helper'

class ContractsTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:senior_application_manager_one)
  end

  test 'should be able to view the list of contracts' do
    project  = projects(:test_application)
    contract = create_contract(project)

    visit project_path(project)
    click_on('Contracts')

    dom_id = "\#contract_#{contract.id}"

    assert has_link?(href: new_project_contract_path(project))
    assert has_selector?(dom_id)

    within(dom_id) do
      assert has_link?(href: contract_path(contract),      title: 'Details')
      assert has_link?(href: edit_contract_path(contract), title: 'Edit')
      assert has_no_link?(href: contract_path(contract),   title: 'Delete')
    end
  end

  test 'should be able to create a contract' do
    project = projects(:test_application)

    visit project_path(project)
    click_on('Contracts')

    click_link('New')

    select  project.reference,                  from: 'Associated With'
    fill_in 'contract[contract_version]',       with: 'test-0.0.1'
    fill_in 'contract[contract_start_date]',    with: '08/04/2020'
    fill_in 'contract[contract_end_date]',      with: '01/04/2021'
    fill_in 'contract[contract_sent_date]',     with: '01/03/2020'
    fill_in 'contract[contract_returned_date]', with: '21/03/2020'
    fill_in 'contract[contract_executed_date]', with: '01/04/2020'
    attach_file('contract[upload]', file_fixture('contract.txt'))

    assert_difference -> { project.global_contracts.count } do
      assert_difference -> { project.contracts.count } do
        click_button('Create Contract')

        assert_equal project_path(project), current_path
        assert has_text?('Contract created successfully')
        assert has_selector?('#contractsTable', visible: true)
      end
    end
  end

  test 'should be able to update a contract' do
    project  = projects(:test_application)
    contract = create_contract(project)

    visit project_path(project)
    click_on('Contracts')

    click_link(href: edit_contract_path(contract))

    fill_in 'contract[destruction_form_received_date]', with: '01/04/2020'

    assert_changes -> { contract.reload.destruction_form_received_date } do
      click_button('Update Contract')

      assert_equal project_path(project), current_path
      assert has_text?('Contract updated successfully')
      assert has_selector?('#contractsTable', visible: true)
    end
  end

  test 'should be able to destroy a contract' do
    project  = projects(:test_application)
    contract = create_contract(project)

    transition_to_contracting_phase(project)

    visit project_path(project)
    click_on('Contracts')

    assert_difference -> { project.global_contracts.count }, -1 do
      assert_difference -> { project.contracts.count }, -1 do
        accept_prompt do
          click_link(href: contract_path(contract), title: 'Delete')
        end

        assert_equal project_path(project), current_path
        assert has_selector?('#contractsTable', visible: true)
      end
    end

    assert has_text?('Contract destroyed successfully')
  end

  test 'should be able to view a contract' do
    project  = projects(:test_application)
    contract = create_contract(project)

    visit project_path(project)
    click_on('Contracts')

    click_link(href: contract_path(contract), title: 'Details')
    assert_equal contract_path(contract), current_path
  end

  test 'should be able to download attached document' do
    project  = projects(:test_application)
    contract = create_contract(project)

    visit project_path(project)
    click_on('Contracts')

    click_link(href: contract_path(contract), title: 'Details')
    assert_equal contract_path(contract), current_path

    accept_prompt do
      click_link(href: download_contract_path(contract))
    end

    wait_for_download
    assert_equal 1, downloads.count
  end

  test 'should redirect if unauthorized' do
    sign_out users(:application_manager_one)
    sign_in  users(:standard_user)

    project  = projects(:test_application)
    contract = create_contract(project)

    visit edit_contract_path(contract)

    refute_equal edit_contract_path(contract), current_path
    assert has_text?('You are not authorized to access this page.')
  end

  private

  def transition_to_contracting_phase(project)
    project.transition_to!(workflow_states(:submitted))

    create_dpia(project)
    project.transition_to!(workflow_states(:dpia_start))
    project.transition_to!(workflow_states(:dpia_review))
    project.transition_to!(workflow_states(:dpia_moderation))

    project.transition_to!(workflow_states(:contract_draft))
  end
end
