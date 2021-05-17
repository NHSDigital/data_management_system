require 'test_helper'

class CommunicationTest < ActiveSupport::TestCase
  def setup
    @communication = communications(:incoming)
  end

  test 'belongs to a project' do
    assert_instance_of Project, @communication.project
  end

  test 'has many children' do
    assert_instance_of Communication, @communication.children.first
  end

  test 'belongs to a parent' do
    assert_instance_of Communication, communications(:outgoing).parent
  end

  test 'belongs to a sender' do
    assert_instance_of User, @communication.sender
  end

  test 'belongs to a recipient' do
    assert_instance_of User, @communication.recipient
  end

  test 'is commentable' do
    assert_includes Communication.included_modules, Commentable
  end

  test 'is audited' do
    with_versioning do
      assert_auditable @communication
    end
  end

  test 'is invalid without a project' do
    @communication.project = nil
    @communication.valid?

    assert_includes @communication.errors.details[:project], error: :blank
    assert_raises { @communication.save!(validate: false) }
  end

  test 'is valid without a parent' do
    @communication.parent = nil
    @communication.valid?

    assert_empty @communication.errors.details[:parent]
    assert_nothing_raised { @communication.save!(validate: false) }
  end

  test 'is invalid without a sender' do
    @communication.sender = nil
    @communication.valid?

    assert_includes @communication.errors.details[:sender], error: :blank
    assert_raises { @communication.save!(validate: false) }
  end

  test 'is invalid without a recipient' do
    @communication.recipient = nil
    @communication.valid?

    assert_includes @communication.errors.details[:recipient], error: :blank
    assert_raises { @communication.save!(validate: false) }
  end

  test 'is invalid without a medium' do
    @communication.medium = nil
    @communication.valid?

    assert_includes @communication.errors.details[:medium], error: :blank
  end

  test 'is invalid without a sent/received date' do
    @communication.contacted_at = nil
    @communication.valid?

    assert_includes @communication.errors.details[:contacted_at], error: :blank
    assert_raises { @communication.save!(validate: false) }
  end

  test 'is invalid with a future sent/received date' do
    @communication.contacted_at = 1.day.from_now
    @communication.valid?

    assert_includes @communication.errors.details[:contacted_at], error: :no_future, no_future: true
  end

  test 'is invalid with a sent/received date before parent date' do
    communication = communications(:outgoing)
    communication.contacted_at = communication.parent_contacted_at - 1.day
    communication.valid?

    error = {
      error:      :not_before,
      not_before: :parent_contacted_at,
      comparison: 'Parent contacted at'
    }

    assert_includes communication.errors.details[:contacted_at], error
  end
end
