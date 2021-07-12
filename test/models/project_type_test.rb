require 'test_helper'

class ProjectTypeTest < ActiveSupport::TestCase
  test 'to_lookup_key' do
    project_type = project_types(:application)

    assert_equal :application, project_type.to_lookup_key
  end
end
