require 'test_helper'

module Workflow
  # Tests behaviour of the Workflow::Model Concern
  class ModelTest < ActiveSupport::TestCase
    def setup
      @project = projects(:dummy_project)
    end

    test 'should have many project_states' do
      assert_instance_of ProjectState, @project.project_states.first
    end

    test 'should have many states' do
      assert_instance_of State, @project.states.first
    end

    test 'should have one current_project_state' do
      assert_instance_of CurrentProjectState, @project.current_project_state
    end

    test 'should have one current_state' do
      assert_instance_of State, @project.current_state
    end

    test 'should have many transitionable_states' do
      assert_instance_of State, @project.transitionable_states.first
    end

    test 'should have a temporally_assigned_user delegate' do
      assert_equal users(:standard_user1), @project.temporally_assigned_user
    end

    test 'transitionable_states should be scoped to project type' do
      Transition.create(
        project_type: project_types(:project),
        from_state: workflow_states(:draft),
        next_state: workflow_states(:step_two)
      )

      assert_includes @project.transitionable_states, workflow_states(:step_one)
      refute_includes @project.transitionable_states, workflow_states(:step_two)
    end

    test 'in_progress scope' do
      assert_includes Project.in_progress, @project

      @project.project_states.build(state: workflow_states(:finished)).
        save(validate: false)

      refute_includes Project.in_progress, @project
    end

    test 'finished scope' do
      refute_includes Project.finished, @project

      @project.project_states.build(state: workflow_states(:finished)).
        save(validate: false)

      assert_includes Project.finished, @project
    end

    test 'should initialize workflow' do
      project = Project.new(project_type: project_types(:dummy), name: 'Dummy #1')

      assert_difference -> { project.project_states.size } do
        project_state = project.initialize_workflow
        assert_equal workflow_states(:draft), project_state.state
      end
    end

    test 'should not initialize workflow if already done so' do
      state   = workflow_states(:step_one)
      project = build_project(project_type: project_types(:dummy))

      project.project_states.build(state: state)

      assert_no_changes -> { project.project_states } do
        project.initialize_workflow
      end
    end

    test 'should initialize workflow before create' do
      project = build_project(project_type: project_types(:dummy), name: 'Dummy #1')

      project.expects(:initialize_workflow)
      project.save
    end

    test 'should know when ready to transition to a new state' do
      assert @project.can_transition_to? workflow_states(:step_one)
      refute @project.can_transition_to? workflow_states(:step_two)
    end

    test 'should be able to define custom transitionable criteria' do
      state = workflow_states(:step_one)
      assert @project.can_transition_to?(state)

      def @project.reasons_not_to_transition_to_step_one
        { base: :just_not_ready }
      end

      refute @project.can_transition_to?(state)
    end

    test 'should transition between states' do
      state = workflow_states(:step_one)

      assert_difference -> { @project.project_states.reload.count } do
        @project.transition_to(state)
        assert_equal state, @project.current_state
      end
    end

    test 'should not be able to transition when not ready' do
      state = workflow_states(:step_one)

      def @project.reasons_not_to_transition_to_step_one
        { base: :just_not_ready }
      end

      def @project.reasons_not_to_transition_to_step_two
        { base: :now_is_not_the_time }
      end

      assert_no_difference(-> { @project.project_states.count }) do
        refute @project.transition_to(state)
      end

      assert_includes @project.errors.details[:base], error: :just_not_ready
      refute_includes @project.errors.details[:base], error: :now_is_not_the_time
    end

    test 'should explode when a state transition fails' do
      state = workflow_states(:step_one)

      assert_raises do
        @project.transition_to!(state) do |_, project_state|
          project_state.readonly!
        end
      end
    end

    test 'state transitions should be atomic' do
      state = workflow_states(:step_one)

      assert_no_difference -> { @project.project_states.reload.count } do
        assert_no_changes -> { @project.reload.description } do
          @project.transition_to(state) do
            @project.description = 'RAWR!'
            1 / 0
          end

          refute_equal state, @project.current_state
        end
      end
    end

    test 'refreshes cached workflow state information' do
      @project.transition_to!(workflow_states(:step_one))

      assert_changes -> { @project.current_state } do
        assert_changes -> { @project.current_project_state } do
          assert_changes -> { @project.transitionable_states.count } do
            @project.project_states.create!(state: workflow_states(:step_two))

            @project.refresh_workflow_state_information
          end
        end
      end
    end

    test 'refreshes cached workflow state information on transition' do
      state = workflow_states(:step_one)

      @project.expects(:refresh_workflow_state_information)
      @project.transition_to(state)
    end

    test 'should publish state changes' do
      state   = workflow_states(:step_one)
      payload = { project: @project, transition: [@project.current_state, state] }

      ActiveSupport::Notifications.expects(:instrument).with('transition.project', payload)

      @project.transition_to(state)
    end

    # FIXME: This test is failing in isolation. Related to changes introduced in #22203 ?
    test 'returning to draft should reset approvals' do
      project = projects(:rejected_project)
      assert_equal 'DRAFT', project.previous_state_id, "Previous state should have been 'DRAFT'"
      assert_changes -> { project.details_approved }, from: false, to: nil do
        assert_changes -> { project.members_approved }, from: false, to: nil do
          assert_changes -> { project.legal_ethical_approved }, from: false, to: nil do
            project.transition_to!(workflow_states(:draft), project.owner)
          end
        end
      end

      assert_equal 0, project.project_nodes.where(approved: [true, false]).count
    end

    test 'should prevent transition if project has unjustifed data items' do
      project = projects(:new_project)
      state   = workflow_states(:review)

      project.stubs(unjustified_data_items: 1)
      refute project.transition_to(state)
      assert_includes project.errors.details[:data_items], error: :unjustified

      project.stubs(unjustified_data_items: 0)
      assert project.transition_to(state)
    end

    test 'should validate unjustified_data_items only in the context of transition' do
      project = projects(:new_project)

      project.stubs(unjustified_data_items: 1)
      project.project_states.build(state: workflow_states(:review))

      project.valid?
      refute_includes project.errors.details[:data_items], error: :unjustified

      project.valid?(:transition)
      assert_includes project.errors.details[:data_items], error: :unjustified
    end

    test 'should prevent transition if project has outstanding sub-approvals' do
      project = projects(:pending_project)
      assert project.valid?
      assert project.owner_grant.valid?
      state = workflow_states(:rejected)

      project.stubs(
        details_approved: nil,
        members_approved: nil,
        legal_ethical_approved: nil,
        data_items_approved: nil
      )
      refute project.transition_to(state)
      assert_includes project.errors.details[:base], error: :outstanding_approvals

      project.stubs(
        details_approved: true,
        members_approved: true,
        legal_ethical_approved: true,
        data_items_approved: true
      )
      assert project.transition_to!(state)
    end

    test 'should validate sub-approvals only in the context of transition' do
      project = projects(:pending_project)

      project.stubs(
        details_approved: nil,
        members_approved: nil,
        legal_ethical_approved: nil,
        data_items_approved: nil
      )
      project.project_states.build(state: workflow_states(:rejected))

      project.valid?
      refute_includes project.errors.details[:base], error: :outstanding_approvals

      project.valid?(:transition)
      assert_includes project.errors.details[:base], error: :outstanding_approvals
    end

    test 'should not be able to approve a project with rejected sub-approvals' do
      project = projects(:pending_project)

      project.stubs(
        details_approved: false,
        members_approved: false,
        legal_ethical_approved: false,
        data_items_approved: false
      )

      refute project.transition_to(workflow_states(:approved))
      assert_includes project.errors.details[:base], error: :not_approvable
    end

    test 'should not be able to submit applications without proper attachments' do
      project = projects(:test_application)

      assert project.transition_to(workflow_states(:submitted))
      assert project.transition_to(workflow_states(:dpia_start))

      project.dpias.destroy_all
      refute project.transition_to(workflow_states(:dpia_review))
      assert_includes project.errors.details[:base], error: :no_attached_dpia

      create_dpia(project)
      assert project.transition_to(workflow_states(:dpia_review))
      assert project.transition_to(workflow_states(:dpia_moderation))

      project.contracts.destroy_all
      refute project.transition_to(workflow_states(:contract_draft))
      assert_includes project.errors.details[:base], error: :no_attached_contract

      create_contract(project)
      assert project.transition_to(workflow_states(:contract_draft))
    end

    test 'return previous state' do
      project = projects(:test_application)
      assert_nil project.previous_state

      project.transition_to!(workflow_states(:submitted))
      assert_equal 'DRAFT', project.previous_state_id
    end

    test 'transitionable_states if current state rejected includes previous state' do
    project = projects(:test_application)
      project.transition_to!(workflow_states(:submitted))
      project.transition_to!(workflow_states(:rejected))
      assert_equal 1, project.transitionable_states.size
      assert_includes project.transitionable_states, workflow_states(:submitted)

      project.transition_to!(workflow_states(:submitted))
      project.transition_to!(workflow_states(:dpia_start))
      project.transition_to!(workflow_states(:rejected))
      assert_equal 1, project.transitionable_states.size
      assert_includes project.transitionable_states, workflow_states(:dpia_start)
    end

    test 'should not be able to submit cas applications without user details' do
      project = create_project(project_type: project_types(:cas), owner: users(:no_roles))
      project.reload_current_state
      # give all cas user details except job_title
      project.owner.update(telephone: '01234 5678910', line_manager_name: 'Line Manager',
                           line_manager_email: 'linemanager@test.co.uk',
                           line_manager_telephone: '10987 654321', employment: 'Contract',
                           contract_start_date: '01/01/2021', contract_end_date: '30/06/2021')

      refute project.transition_to(workflow_states(:submitted))

      project.owner.update(job_title: 'Tester')
      project.reload

      assert project.transition_to(workflow_states(:submitted))
    end

    test 'should not require contract start and end date if employment is permanent' do
      project = create_project(project_type: project_types(:cas), owner: users(:no_roles))
      project.reload_current_state
      # give all cas user details except job_title
      project.owner.update(job_title: 'Tester', telephone: '01234 5678910',
                           line_manager_name: 'Line Manager',
                           line_manager_email: 'linemanager@test.co.uk',
                           line_manager_telephone: '10987 654321', employment: 'Permanent',
                           contract_start_date: nil, contract_end_date: nil)

      assert project.transition_to(workflow_states(:submitted))
    end

    private

    def add_attachment(project, type, filename: 'foo.txt', contents: SecureRandom.hex)
      file = ActionDispatch::Http::UploadedFile.new(
        tempfile: StringIO.new(contents),
        filename: filename,
        type:     'text/plain'
      )

      project.project_attachments.create!(name: type, upload: file)
    end
  end
end
