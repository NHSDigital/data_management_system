require 'test_helper'

class ReleaseTest < ActiveSupport::TestCase
  test 'should belong to a project' do
    project = projects(:one)
    release = project.releases.build

    assert_equal project, release.project
    assert_includes project.releases, release
  end

  test 'should be invalid without a project' do
    release = Release.new
    release.valid?

    assert_includes release.errors.details[:project], error: :blank

    release.project = projects(:one)
    release.valid?

    refute_includes release.errors.details[:project], error: :blank
  end

  test 'should be associated with a project state' do
    project = projects(:one)
    release = project.releases.build

    release.valid?

    assert_equal project.current_project_state, release.project_state
  end

  test 'should be invalid without an associated project state' do
    release = Release.new
    release.valid?

    assert_includes release.errors.details[:project_state], error: :blank
  end

  test 'should be auditable' do
    project = projects(:one)
    release = project.releases.build

    with_versioning do
      assert_auditable release
    end
  end

  test 'should validate numericality of actual_cost' do
    project = projects(:one)
    release = project.releases.build

    release.actual_cost = 'not a number'
    release.valid?
    assert_includes release.errors.details[:actual_cost], error: :not_a_number, value: 'not a number'

    release.actual_cost = 1000.00
    release.valid?
    assert_empty release.errors.details[:actual_cost]

    release.actual_cost = nil
    release.valid?
    assert_empty release.errors.details[:actual_cost]
  end
end
