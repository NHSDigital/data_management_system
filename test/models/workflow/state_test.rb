require 'test_helper'

module Workflow
  # Test behaviour of the State class.
  class StateTest < ActiveSupport::TestCase
    def setup
      @state = workflow_states(:draft)
    end

    test 'should have many transitions' do
      assert_instance_of Transition, @state.transitions.first
    end

    test 'should have many transitionable states' do
      assert_instance_of State, @state.transitionable_states.first
    end

    test 'terminal scope' do
      scoped = State.terminal
      refute_includes scoped, workflow_states(:draft)
      assert_includes scoped, workflow_states(:finished)
    end

    test 'non_terminal scope' do
      scoped = State.non_terminal
      assert_includes scoped, workflow_states(:draft)
      refute_includes scoped, workflow_states(:finished)
    end

    test 'not_deleted scope' do
      scoped = State.not_deleted
      refute_includes scoped, workflow_states(:deleted)
    end

    test 'inactive scope' do
      scoped = State.inactive
      assert_equal 4, scoped.count
      assert_includes scoped, workflow_states(:deleted)
      assert_includes scoped, workflow_states(:suspended)
      assert_includes scoped, workflow_states(:closed)
      assert_includes scoped, workflow_states(:expired)
    end

    test 'active scope' do
      scoped = State.active
      refute_includes scoped, workflow_states(:deleted)
      refute_includes scoped, workflow_states(:suspended)
      refute_includes scoped, workflow_states(:closed)
      refute_includes scoped, workflow_states(:expired)
    end

    test 'awaiting_sign_off scope' do
      scoped = State.awaiting_sign_off
      assert_includes scoped, workflow_states(:draft)
      assert_includes scoped, workflow_states(:review)
      assert_includes scoped, workflow_states(:submitted)
    end

    test 'closed scope' do
      scoped = State.closed

      assert_equal 5, scoped.size
      assert_includes scoped, workflow_states(:approved)
      assert_includes scoped, workflow_states(:rejected)
      assert_includes scoped, workflow_states(:closed)
      assert_includes scoped, workflow_states(:deleted)
      assert_includes scoped, workflow_states(:data_destroyed)
    end

    test 'open scope' do
      scoped = State.open

      refute_includes scoped, workflow_states(:approved)
      refute_includes scoped, workflow_states(:rejected)
      refute_includes scoped, workflow_states(:closed)
      refute_includes scoped, workflow_states(:deleted)
      refute_includes scoped, workflow_states(:data_destroyed)
    end

    test 'closed?' do
      closed_state = workflow_states(:closed)
      open_state   = workflow_states(:submitted)

      assert closed_state.closed?
      refute open_state.closed?
    end

    test 'open?' do
      closed_state = workflow_states(:closed)
      open_state   = workflow_states(:submitted)

      refute closed_state.open?
      assert open_state.open?
    end

    test 'returns a translated name relative to project type context' do
      translations = {
        'workflow/state': {
          eoi: { draft: 'New' },
          application: { draft: 'New' },
          project: { draft: 'Drafting' }
        }
      }

      backend = I18n::Backend::KeyValue.new({})
      backend.store_translations(:en, translations)
      I18n.config.stubs(backend: backend)

      state = workflow_states(:draft)

      # with no provided context
      assert_equal state.id, state.name

      # fallback when no translations found
      assert_equal state.id, state.name(project_types(:dummy))

      # with one context
      assert_equal 'New', state.name(project_types(:eoi))

      # with multiple contexts (common names)
      assert_equal 'New', state.name(project_types(:eoi), project_types(:application))

      # with multiple contexts (unique names)
      assert_equal 'New/Drafting', state.name(project_types(:eoi), project_types(:project))
    end
  end
end
