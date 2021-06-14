require 'test_helper'

# Tests behaviour of ProjectsMailer
class ProjectsMailerTest < ActionMailer::TestCase
  test 'project assignment' do
    assigned_user = users(:application_manager_one)
    project       = build_project(project_type: project_types(:eoi), assigned_user: assigned_user)

    project.save(validate: false)
    project.reload_current_state

    email = ProjectsMailer.with(project: project, assigned_to: assigned_user).project_assignment

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal [assigned_user.email], email.to
    assert_equal 'Project Assignment', email.subject
    assert_match %r{a href="http://[^/]+/projects/#{project.id}"}, email.html_part.body.to_s
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'project awaiting assignment' do
    project = build_project(project_type: project_types(:eoi))
    project.save(validate: false)

    email = ProjectsMailer.with(project: project).project_awaiting_assignment

    assert_emails 1 do
      email.deliver_later
    end

    assert_equal User.odr_users.map(&:email), email.to
    assert_equal 'Project Awaiting Assignment', email.subject
    assert_match %r{a href="http://[^/]+/projects/#{project.id}"}, email.html_part.body.to_s
    assert_match %r{http://[^/]+/projects/#{project.id}}, email.text_part.body.to_s
  end

  test 'should not send project assignment email when not odr or mbis' do
    assigned_user = users(:application_manager_one)
    project       = build_project(project_type: project_types(:cas), assigned_user: assigned_user)

    project.save(validate: false)

    email = ProjectsMailer.with(project: project, assigned_to: assigned_user).project_assignment

    assert_emails 0 do
      email.deliver_later
    end
  end

  test 'should not send project awaiting assignment email when not odr or mbis' do
    assigned_user = users(:application_manager_one)
    project       = build_project(project_type: project_types(:cas), assigned_user: assigned_user)

    project.save(validate: false)

    email = ProjectsMailer.with(project: project).project_awaiting_assignment

    assert_emails 0 do
      email.deliver_later
    end
  end

  test 'mail from beta stack displays beta' do
    Mbis.stubs(:stack).returns('beta')
    assert_equal 'beta', Mbis.stack
    email = ProjectsMailer.with(project: projects(:one)).project_awaiting_assignment
    assert_includes(email.from_address.to_s, 'DMS BETA')
  end

  test 'mail from live stack displays live' do
    Mbis.stubs(:stack).returns('live')
    assert_equal 'live', Mbis.stack
    email = ProjectsMailer.with(project: projects(:one)).project_awaiting_assignment
    assert_includes(email.from_address.to_s, 'DMS LIVE')
  end
end
