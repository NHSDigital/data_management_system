require 'test_helper'

class ProjectRelationshipTest < ActiveSupport::TestCase
  test 'belongs to a pair of projects' do
    relationship = project_relationships(:dummy_project_test_application)

    assert_instance_of Project, relationship.left_project
    assert_instance_of Project, relationship.right_project
  end

  test 'is invalid without a left project' do
    relationship = ProjectRelationship.new(right_project: projects(:dummy_project))

    refute relationship.valid?
    assert_includes relationship.errors.details[:left_project], error: :blank

    assert_raises ActiveRecord::NotNullViolation do
      relationship.save(validate: false)
    end
  end

  test 'is invalid without a right project' do
    relationship = ProjectRelationship.new(left_project: projects(:dummy_project))

    refute relationship.valid?
    assert_includes relationship.errors.details[:right_project], error: :blank

    assert_raises ActiveRecord::NotNullViolation do
      relationship.save(validate: false)
    end
  end

  test 'is invalid if already exists' do
    relationship = ProjectRelationship.new(
      left_project:  projects(:dummy_project),
      right_project: projects(:test_application)
    )

    refute relationship.valid?
    assert_includes relationship.errors.details[:base], error: :taken

    assert_raises ActiveRecord::RecordNotUnique do
      relationship.save(validate: false)
    end
  end

  test 'is invalid if an inverse pair already exists' do
    relationship = ProjectRelationship.new(
      left_project:  projects(:test_application),
      right_project: projects(:dummy_project)
    )

    refute relationship.valid?
    assert_includes relationship.errors.details[:base], error: :taken

    assert_raises ActiveRecord::RecordNotUnique do
      relationship.save(validate: false)
    end
  end

  test 'is invalid if self-referential' do
    relationship = ProjectRelationship.new(
      left_project:  projects(:dummy_project),
      right_project: projects(:dummy_project)
    )

    refute relationship.valid?
    assert_includes relationship.errors.details[:base], error: :self_referential

    assert_raises ActiveRecord::StatementInvalid do
      relationship.save(validate: false)
    end
  end
end
