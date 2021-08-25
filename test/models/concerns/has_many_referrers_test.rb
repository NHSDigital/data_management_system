require 'test_helper'

# Tests behaviour of the `HasManyReferers` concern.
class HasManyReferersTest < ActiveSupport::TestCase
  def setup
    @resource = projects(:dummy_project)
  end

  test 'should have many referrers' do
    assert @resource.class.reflect_on_association(:contracts)
    assert @resource.class.reflect_on_association(:releases)
    assert @resource.class.reflect_on_association(:dpias)

    assert_instance_of ::Contract, @resource.contracts.build
    assert_instance_of ::Release,  @resource.releases.build
    assert_instance_of ::DataPrivacyImpactAssessment, @resource.dpias.build
  end
end
