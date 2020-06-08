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
  end
end
