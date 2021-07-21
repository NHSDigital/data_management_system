require 'test_helper'

class ProjectImportTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:application_manager_one)

    sign_in @user

    visit terms_and_conditions_path
    click_on 'Accept'
  end

  test 'should not be able to import application PDF forms without an :application_manager role' do
    sign_out :user
    sign_in users(:senior_project_user)

    visit team_path(teams(:team_two))

    assert_equal team_path(teams(:team_two)), current_path
    assert has_no_button? 'Import'
    assert has_no_field? 'file'
  end

  test 'should be able to import application PDF forms as an :application_manager role' do
    team = teams(:team_two)

    visit team_path(team)
    assert_equal team_path(team), current_path

    click_button 'Import'

    assert_difference -> { team.projects.count } do
      assert_difference -> { ProjectAttachment.count } do
        file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')

        attach_file(file) do
          find('.glyphicon-inbox').click
        end

        within '#project_header' do
          assert has_text? 'My Test Import Project'
        end
      end
    end
  end

  test 'should provide at least some modicum of feedback when import fails' do
    team = teams(:team_two)

    visit team_path(team)
    assert_equal team_path(team), current_path

    click_button 'Import'

    # Invalid record(s)...
    assert_no_difference -> { team.projects.count } do
      file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v6-alpha.blank.pdf')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        assert has_text? "Email can't be blank"

        click_button 'OK'
      end
    end

    # Wrong file type...
    assert_no_difference -> { team.projects.count } do
      file = Pathname.new(fixture_path).join('files', 'empty.test')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        assert has_text? 'Unpermitted file type'

        click_button 'OK'
      end
    end

    # Bad PDF...
    assert_no_difference -> { team.projects.count } do
      PDF::Reader.any_instance.stubs(:acroform_data).raises(RuntimeError, 'Bang!')
      file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        assert has_text?(/fingerprint.*[0-9a-f]{32}/)

        click_button 'OK'
      end
    end
  end

  test 'projects can be updated via PDF import' do
    file    = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')
    project = create_project(
      project_type:    project_types(:application),
      name:            'Provisional Title',
      project_purpose: 'Tests importing PDF files'
    )

    visit edit_project_path(project)

    assert has_text?('Drag and drop PDF here')

    assert_changes -> { project.reload.updated_at } do
      assert_difference -> { project.project_attachments.count } do
        attach_file(file) do
          find('.glyphicon-inbox').click
        end

        assert has_no_text?('Provisional Title')
        assert has_text?('My Test Import Project')
        assert_equal project_path(project), current_path
      end
    end
  end

  test 'projects cannot be updated via PDF import by unpriveledged user' do
    project = create_project(
      project_type: project_types(:application),
      project_purpose: 'Import testing'
    )

    sign_out :user
    sign_in users(:standard_user2)

    visit edit_project_path(project)

    assert has_no_text?('Drag and drop PDF here')
  end

  test 'not all project types support update via PDF import' do
    project = create_project(
      project_type: project_types(:eoi),
      project_purpose: 'Import testing'
    )

    visit edit_project_path(project)

    assert has_no_text?('Drag and drop PDF here')
  end
end
