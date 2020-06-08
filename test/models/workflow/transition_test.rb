require 'test_helper'

module Workflow
  # Tests behaviour of the Transition class.
  class TransitionTest < ActiveSupport::TestCase
    def setup
      @transition = workflow_transitions(:one)
    end

    test 'should belong to an initial State' do
      assert_instance_of State, @transition.from_state
    end

    test 'should belong to a final State' do
      assert_instance_of State, @transition.next_state
    end

    test 'should optionally belong to a ProjectType' do
      assert_instance_of ProjectType, @transition.project_type
    end

    test 'should be invalid without a from_state' do
      @transition.from_state = nil
      @transition.valid?

      assert_includes @transition.errors.details[:from_state], error: :blank
    end

    test 'should be invalid without a next_state' do
      @transition.next_state = nil
      @transition.valid?

      assert_includes @transition.errors.details[:next_state], error: :blank
    end

    test 'should not be invalid without a project_type' do
      @transition.project_type = nil
      @transition.valid?

      refute_includes @transition.errors.details[:project_type], error: :blank
    end

    test 'applicable_to scope' do
      assert_includes Transition.applicable_to(project_types(:dummy)), @transition
      refute_includes Transition.applicable_to(project_types(:project)), @transition

      @transition.update(project_type: nil)

      assert_includes Transition.applicable_to(project_types(:dummy)), @transition
      assert_includes Transition.applicable_to(project_types(:project)), @transition
    end
  end
end
