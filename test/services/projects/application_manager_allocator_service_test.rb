require 'test_helper'

module Projects
  class ApplicationManagerAllocatorServiceTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test 'should assigned application managers based on least number of active projects' do
      team = teams(:team_one)

      application_manager_one   = users(:application_manager_one)
      application_manager_two   = users(:application_manager_two)
      application_manager_three = users(:application_manager_three)

      queue = [
        application_manager_three,
        application_manager_two,
        application_manager_one
      ]

      6.times do |i|
        application_manager = queue.shift

        build_project(
          project_type: project_types(:eoi),
          name: "Allocation Test #{i}",
          project_purpose: 'Test',
          team: team,
          senior_user_id: users(:standard_user2).id,
          assigned_user: application_manager
        ).save!

        queue.push(application_manager)
      end

      # Spoof an approved state...
      application_manager_two.assigned_projects.last.
        project_states.last.update_column(:state_id, workflow_states(:approved).id)

      project = build_project(
        project_type: project_types(:eoi),
        name: 'New Allocation Test',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id
      )

      ApplicationManagerAllocatorService.call(project: project)

      assert_equal application_manager_two, project.assigned_user
    end

    test 'should ensure application managers with empty workloads are included' do
      team = teams(:team_one)

      application_manager_one   = users(:application_manager_one)
      application_manager_two   = users(:application_manager_two)
      application_manager_three = users(:application_manager_three)

      queue = [
        application_manager_two,
        application_manager_one
      ]

      2.times do |i|
        application_manager = queue.shift

        build_project(
          project_type: project_types(:eoi),
          name: "Allocation Test #{i}",
          project_purpose: 'Test',
          team: team,
          senior_user_id: users(:standard_user2).id,
          assigned_user: application_manager
        ).save!

        queue.push(application_manager)
      end

      project = build_project(
        project_type: project_types(:eoi),
        name: 'New Allocation Test',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id
      )

      ApplicationManagerAllocatorService.call(project: project)

      assert_equal application_manager_three, project.assigned_user
    end

    test 'should fall back to name ordering to resolve tied allocation counts' do
      team = teams(:team_one)

      application_manager_one   = users(:application_manager_one)
      application_manager_two   = users(:application_manager_two)
      application_manager_three = users(:application_manager_three)

      queue = [
        application_manager_three,
        application_manager_two,
        application_manager_one
      ]

      3.times do |i|
        application_manager = queue.shift

        build_project(
          project_type: project_types(:eoi),
          name: "Allocation Test #{i}",
          project_purpose: 'Test',
          team: team,
          senior_user_id: users(:standard_user2).id,
          assigned_user: application_manager
        ).save!

        queue.push(application_manager)
      end

      project = build_project(
        project_type: project_types(:eoi),
        name: 'New Allocation Test',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id
      )

      ApplicationManagerAllocatorService.call(project: project)

      assert_equal application_manager_one, project.assigned_user
    end

    test 'should not fail when there are no available application managers' do
      ApplicationManagerAllocatorService.any_instance.stubs(allocation_threshold: 1)

      team = teams(:team_one)

      application_manager_one   = users(:application_manager_one)
      application_manager_two   = users(:application_manager_two)
      application_manager_three = users(:application_manager_three)

      queue = [
        application_manager_three,
        application_manager_two,
        application_manager_one
      ]

      3.times do |i|
        application_manager = queue.shift

        build_project(
          project_type: project_types(:eoi),
          name: "Allocation Test #{i}",
          project_purpose: 'Test',
          team: team,
          senior_user_id: users(:standard_user2).id,
          assigned_user: application_manager
        ).save!

        queue.push(application_manager)
      end

      project = build_project(
        project_type: project_types(:eoi),
        name: 'New Allocation Test',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id
      )

      assert_nothing_raised do
        ApplicationManagerAllocatorService.call(project: project)
        assert_nil project.assigned_user
      end
    end

    test 'should not reassign an application manager' do
      team    = teams(:team_one)
      project = build_project team: team, senior_user_id: users(:standard_user2).id

      ApplicationManagerAllocatorService.call(project: project)

      assert_no_changes -> { project.assigned_user } do
        ApplicationManagerAllocatorService.call(project: project)
      end
    end

    test 'should not assign to inactive application managers' do
      team = teams(:team_one)

      application_manager_one   = users(:application_manager_one)
      application_manager_two   = users(:application_manager_two)
      application_manager_three = users(:application_manager_three)

      application_manager_one.update(z_user_status: z_user_statuses(:suspended_user_status))

      queue = [
        application_manager_three,
        application_manager_two
      ]

      2.times do |i|
        application_manager = queue.shift

        build_project(
          project_type: project_types(:eoi),
          name: "Allocation Test #{i}",
          project_purpose: 'Test',
          team: team,
          senior_user_id: users(:standard_user2).id,
          assigned_user: application_manager
        ).save!

        queue.push(application_manager)
      end

      project = build_project(
        project_type: project_types(:eoi),
        name: 'New Allocation Test',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id
      )

      ApplicationManagerAllocatorService.call(project: project)

      refute_equal application_manager_one, project.assigned_user
    end

    test 'should assign to previous application manager is project is a clone' do
      team = teams(:team_one)

      application_manager = users(:application_manager_two)

      initial_project = build_project(
        project_type: project_types(:eoi),
        name: 'Clone Allocation Test 1',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id,
        assigned_user: application_manager
      )
      initial_project.save

      clone_project = build_project(
        project_type: project_types(:eoi),
        name: 'Clone Allocation Test 2',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id,
        clone_of: initial_project.id
      )

      ApplicationManagerAllocatorService.call(project: clone_project)

      assert_equal application_manager, clone_project.assigned_user
    end

    test 'should not assign to previous application manager if not currently active' do
      team = teams(:team_one)

      application_manager = users(:application_manager_two)

      initial_project = build_project(
        project_type: project_types(:eoi),
        name: 'Clone Allocation Test 1',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id,
        assigned_user: application_manager
      )
      initial_project.save

      application_manager.update(z_user_status: z_user_statuses(:suspended_user_status))

      clone_project = build_project(
        project_type: project_types(:eoi),
        name: 'Clone Allocation Test 2',
        project_purpose: 'Test',
        team: team,
        senior_user_id: users(:standard_user2).id,
        clone_of: initial_project.id
      )

      ApplicationManagerAllocatorService.call(project: clone_project)

      refute_equal application_manager, clone_project.assigned_user
    end

    test 'should generate alerts on successful allocation' do
      project = build_project(
        project_type: project_types(:eoi),
        project_purpose: 'Test'
      )

      ProjectsNotifier.expects(:project_assignment)
      assert_emails 1 do
        ApplicationManagerAllocatorService.call(project: project)
      end
    end

    test 'should generate alerts on unsuccessful allocation' do
      project = build_project(
        project_type: project_types(:eoi),
        project_purpose: 'Test'
      )
      project.save

      ApplicationManagerAllocatorService.any_instance.stubs(allocation_threshold: 0)
      ProjectsNotifier.expects(:project_awaiting_assignment)
      assert_emails 1 do
        ApplicationManagerAllocatorService.call(project: project)
      end
    end
  end
end
