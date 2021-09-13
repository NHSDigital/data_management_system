require 'test_helper'

class ReleaseTest < ActiveSupport::TestCase
  def setup
    @contract_completed_project ||= projects(:test_application)
    %w[SUBMITTED DPIA_START DPIA_REVIEW DPIA_MODERATION CONTRACT_DRAFT CONTRACT_COMPLETED].each do |state|
      Workflow::ProjectState.create!(state_id: state,
                                     project_id: @contract_completed_project.id,
                                     user_id: User.first.id)
    end
  end

  test 'should belong to a project' do
    project = projects(:one)
    release = project.global_releases.build

    assert_equal project, release.project
    assert_includes project.global_releases, release
  end

  test 'should be invalid without a project' do
    release = Release.new
    release.valid?

    assert_includes release.errors.details[:project], error: :blank

    release.project = projects(:one)
    release.valid?

    refute_includes release.errors.details[:project], error: :blank
  end

  test 'should include BelongsToReferent' do
    assert_includes Release.included_modules, BelongsToReferent
  end

  test 'should be associated with a project state' do
    project = projects(:one)
    release = project.global_releases.build

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
    release = project.global_releases.build

    with_versioning do
      assert_auditable release
    end
  end

  test 'should validate numericality of actual_cost' do
    project = projects(:one)
    release = project.global_releases.build

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

  test 'should not auto transition to data released if a release date is not present' do
    assert_no_changes -> { @contract_completed_project.current_state } do
      build_release(@contract_completed_project) do |release|
        release.save!
      end
    end
  end

  test 'should auto transition to data released if a any release date is present' do
    assert_changes -> { @contract_completed_project.current_state.id }, 'DATA_RELEASED' do
      build_release(@contract_completed_project) do |release|
        release.release_date = Date.current
        release.save!
      end
    end
  end

  test 'should not auto transition to data released if not in correct previous state' do
    @contract_completed_project.transition_to!(Workflow::State.find_by(id: 'AMEND'))
    assert_no_changes -> { @contract_completed_project.current_state } do
      build_release(@contract_completed_project) do |release|
        release.release_date = Date.current
        release.save!
      end
    end
  end

  private

  def build_release(project, **attributes)
    project.global_releases.build(referent: project, **attributes) do |release|
      yield(release) if block_given?
    end
  end
end
