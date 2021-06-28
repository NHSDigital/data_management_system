require 'test_helper'

module Workflow
  class AssignmentsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @project  = projects(:test_application)
      @user_one = users(:application_manager_one)
      @user_two = users(:application_manager_two)

      sign_in(@user_one)
    end

    test 'should create a new assignment' do
      project_state = @project.current_project_state

      assert_difference -> { Assignment.count } do
        post workflow_project_state_assignments_path(project_state), params: {
          assignment: {
            assigned_user_id: @user_two.id
          }
        }
      end

      assert_redirected_to project_path(@project)
      assert_equal 'Project assigned successfully', flash[:notice]
    end

    test 'should prevent unauthorized access' do
      sign_out(@user_one)
      sign_in(@project.owner)

      project_state = @project.current_project_state
      project_state.assign_to!(user: @user_two)

      assert_no_difference -> { Assignment.count } do
        post workflow_project_state_assignments_path(project_state), params: {
          assignment: {
            assigned_user_id: @user_two.id
          }
        }
      end

      assert_redirected_to root_path
      assert_equal 'You are not authorized to access this page.', flash[:error]
    end

    test 'should prevent assignment of a previous state' do
      previous_state = @project.project_states.build do |project_state|
        project_state.state = workflow_states(:dpia_review)
        project_state.assignments.build(assigned_user: @user_one)

        project_state.save!(validate: false)
      end

      @project.transition_to!(workflow_states(:dpia_moderation)) do |_, project_state|
        project_state.assignments.build(assigned_user: @user_one)
      end

      assert_no_difference -> { Assignment.count } do
        post workflow_project_state_assignments_path(previous_state), params: {
          assignment: {
            assigned_user_id: @user_two.id
          }
        }
      end

      assert_redirected_to project_path(@project)
    end

    test 'should prevent assignment to an inappropriate user' do
      # Force project into a state that has a restricted set of temporally assignable users...
      @project.project_states.build do |project_state|
        project_state.state = workflow_states(:dpia_review)
        project_state.assignments.build(assigned_user: @user_one)

        project_state.save!(validate: false)
      end

      project_state = @project.current_project_state

      assert_no_difference -> { Assignment.count } do
        post workflow_project_state_assignments_path(project_state), params: {
          assignment: {
            assigned_user_id: users(:standard_user1).id
          }
        }
      end

      assert_redirected_to project_path(@project)
      assert_equal 'Could not assign project!', flash[:alert]
    end

    test 'sends notification emails on successful assignment' do
      project_state = @project.current_project_state
      args = {
        project:     @project,
        assigned_to: @user_two,
        assigned_by: @user_one
      }

      assert_enqueued_emails 1 do
        assert_enqueued_email_with ProjectsMailer, :project_assignment, args: args do
          post workflow_project_state_assignments_path(project_state), params: {
            assignment: {
              assigned_user_id: @user_two.id
            }
          }
        end
      end
    end
  end
end
