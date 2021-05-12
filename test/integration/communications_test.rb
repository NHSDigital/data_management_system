require 'test_helper'

class CommunicationsTest < ActionDispatch::IntegrationTest
  def setup
    @project = projects(:test_application)
    @project.grants.create!(
      user: users(:application_manager_one),
      roleable: project_roles(:contributor)
    )

    sign_in users(:application_manager_one)
  end

  test 'can view the communications for a project' do
    communication = create_communication(@project)

    visit project_path(@project)

    within(find_link('Communications')) do
      assert has_selector?('.badge', text: 1)
    end

    click_link 'Communications'

    assert has_selector?('table#communications_table')

    within("\#communication_#{communication.id}") do
      assert has_no_link?('Details')
      assert has_no_link?('Edit')
      assert has_link?('Delete')
      assert has_link?('Comments')
      assert has_link?('Log Response')
    end
  end

  test 'can create a new communication' do
    visit project_path(@project)

    click_link 'Communications'

    within(find_link('Communications')) do
      assert has_selector?('.badge', text: 0)
    end

    within('table#communications_table') do
      assert has_no_selector?('tr.communication')
    end

    click_link 'New'

    assert_difference -> { @project.communications.count } do
      within_modal do
        select  'Standard User',               from: 'communication[sender_id]'
        select  'Application Manager One',     from: 'communication[recipient_id]'
        select  'Email',                       from: 'communication[medium]'
        fill_in 'communication[contacted_at]', with: Time.zone.today.to_s(:ui)

        click_button 'Save'
      end
    end

    within('table#communications_table') do
      assert has_selector?('tr.communication', count: 1)
    end

    within(find_link('Communications')) do
      assert has_selector?('.badge', text: 1)
    end
  end

  test 'can create a communication as a response to another' do
    communication = create_communication(@project)

    visit project_path(@project)

    click_link 'Communications'

    within('table#communications_table') do
      assert has_no_selector?('td', text: "re: #{communication.id}")
    end

    within("\#communication_#{communication.id}") do
      click_link 'Log Response'
    end

    assert_difference -> { communication.children.count } do
      within_modal do
        assert has_select?('communication[sender_id]',    selected: 'Application Manager One')
        assert has_select?('communication[recipient_id]', selected: 'Standard User')

        select  'Email', from: 'communication[medium]'
        fill_in 'communication[contacted_at]', with: Time.zone.today.to_s(:ui)

        click_button 'Save'
      end
    end

    within('table#communications_table') do
      assert has_selector?('td', text: "re: #{communication.id}")
    end
  end

  test 'cannot create an invalid communication' do
    visit project_path(@project)

    click_link 'Communications'

    click_link 'New'

    within_modal(remain: true) do
      assert_no_difference -> { @project.communications.count } do
        click_button 'Save'
      end
    end
  end

  test 'can delete a communication' do
    communication = create_communication(@project)
    selector      = "\#communication_#{communication.id}"

    visit project_path(@project)

    within(find_link('Communications')) do
      assert has_selector?('.badge', text: 1)
    end

    click_link 'Communications'

    assert_difference -> { @project.communications.count }, -1 do
      within(selector) do
        accept_confirm do
          click_link 'Delete'
        end
      end

      assert has_no_selector?(selector)
    end

    within(find_link('Communications')) do
      assert has_selector?('.badge', text: 0)
    end
  end

  test 'should display only to application managers' do
    sign_out :user
    sign_in @project.owner

    visit project_path(@project)

    assert has_no_selector?('#communications',       visible: :all)
    assert has_no_selector?('#communications_table', visible: :all)
    assert has_no_selector?('.communication',        visible: :all)

    visit project_communications_path(@project)
    assert_equal root_path, current_path
    # assert has_text?('not authorized') # NOTE: Flakey (!?!?!)
  end

  private

  def create_communication(project, **attributes)
    attributes.reverse_merge!(
      sender:       users(:standard_user),
      recipient:    users(:application_manager_one),
      contacted_at: Time.zone.today,
      medium:       :email
    )

    project.communications.create!(attributes)
  end
end
