require 'test_helper'

class DataPrivacyImpactAssessmentTest < ActiveSupport::TestCase
  test 'should belong to a project' do
    project = projects(:one)
    dpia    = project.global_dpias.build

    assert_equal project, dpia.project
    assert_includes project.global_dpias, dpia
  end

  test 'should be invalid without a project' do
    dpia = DataPrivacyImpactAssessment.new
    dpia.valid?

    assert_includes dpia.errors.details[:project], error: :blank

    dpia.project = projects(:one)
    dpia.valid?

    refute_includes dpia.errors.details[:project], error: :blank
  end

  test 'should be associated with a project state' do
    project = projects(:one)
    dpia    = create_dpia(project)

    assert_equal project.current_project_state, dpia.project_state
  end

  test 'should include BelongsToReferent' do
    assert_includes DataPrivacyImpactAssessment.included_modules, BelongsToReferent
  end

  test 'should be invalid without an associated project_state' do
    dpia = DataPrivacyImpactAssessment.new
    dpia.valid?

    assert_includes dpia.errors.details[:project_state], error: :blank
  end

  test 'should not permit ig_score outside permissible range' do
    project = projects(:one)
    dpia    = project.global_dpias.build

    dpia.ig_score = -1
    dpia.valid?
    assert_includes dpia.errors.details[:ig_score], error: :inclusion, value: -1

    dpia.ig_score = 101
    dpia.valid?
    assert_includes dpia.errors.details[:ig_score], error: :inclusion, value: 101

    dpia.ig_score = 50
    dpia.valid?
    assert_empty dpia.errors.details[:ig_score]

    dpia.ig_score = nil
    dpia.valid?
    assert_empty dpia.errors.details[:ig_score]
  end

  test 'should not permit fractional ig_score values' do
    project = projects(:one)
    dpia    = project.global_dpias.build(ig_score: 50.0)

    dpia.valid?
    assert_includes dpia.errors.details[:ig_score], error: :not_an_integer, value: 50.0
  end

  test 'should be auditable' do
    project = projects(:one)
    dpia    = project.global_dpias.build

    with_versioning do
      assert_auditable dpia
    end
  end
end
