require 'test_helper'

module Workflow
  # Tests general behaviour of the Workflow::Ability class.
  class AbilityTest < ActiveSupport::TestCase
    def setup
      @new_read_only_user = create_user(username: 'project_read_only',
                                        email: 'project_read_only@phe.gov.uk',
                                        first_name: 'project_read_only',
                                        last_name: 'user')
      ro_grant = Grant.new(roleable: ProjectRole.fetch(:read_only), user: @new_read_only_user)
      @project = create_project(team: teams(:team_one), grants: [ro_grant])
    end

    test 'workflows - as a basic user' do
      # user = users(:standard_user2)

      refute @new_read_only_user.can?(:transition, @project)
      refute @new_read_only_user.can?(:read, @project.project_states.first)
    end

    test 'workflows - as a project member' do
      user = users(:standard_user2)
      @project.grants << Grant.new(roleable: ProjectRole.fetch(:read_only), user: user)

      refute user.can?(:transition, @project)
      assert user.can?(:read, @project.project_states.first)
    end

    test 'workflows - as a project contributor user' do
      user = users(:contributor)
      @project.grants << Grant.new(roleable: ProjectRole.fetch(:contributor), user: user)

      refute user.can?(:transition, @project)
      assert user.can?(:read, @project.project_states.first)
    end

    test 'workflows - as a team delegate user' do
      user = users(:delegate_user1)

      assert user.can?(:transition, @project)
      assert user.can?(:read, @project.project_states.first)
    end

    test 'workflows - as an ODR user' do
      user = users(:odr_user)

      assert user.can?(:transition, @project)
      assert user.can?(:read, @project.project_states.first)
    end

    test 'workflows - as an admin user' do
      user = users(:admin_user)

      refute user.can?(:transition, @project)
      assert user.can?(:read, @project.project_states.first)
    end

    test 'assignments' do
      project    = projects(:dummy_project)
      user       = project.owner
      assignment = project.current_project_state.
                   assignments.
                   build(assigned_user: users(:application_manager_two))

      project.current_project_state.assign_to!(user: user)
      assert user.can?(:create, assignment)

      project.current_project_state.assign_to!(user: users(:application_manager_one))
      refute user.can?(:create, assignment)
    end
  end
end
