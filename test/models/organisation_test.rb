require 'test_helper'

# Tests behaviour of the Organisation class.
class OrganisationTest < ActiveSupport::TestCase
  def setup
    @organisation = organisations(:test_organisation_one)
  end

  test 'should belong to a Country' do
    assert_instance_of Lookups::Country, @organisation.country
  end

  test 'should belong to an OrganisationType' do
    assert_instance_of Lookups::OrganisationType, @organisation.organisation_type
  end

  test 'should have many teams' do
    assert_instance_of Team, @organisation.teams.build
  end

  # TODO - Clarify what happens when destroying an organisation, particulary if any organisation
  # teams have active projects...
  test 'destroying an organisation should remove all of its teams' do
    skip
    expected = @organisation.teams.count

    assert_difference 'Team.count', -expected do
      @organisation.destroy
    end
  end

  test 'should be auditable' do
    with_versioning do
      assert_auditable Organisation
    end
  end

  test 'should be invalid without an OrganisationType' do
    @organisation.organisation_type = nil

    refute @organisation.valid?
    assert_includes @organisation.errors.details[:organisation_type], error: :blank
  end

  test 'should be invalid without a name' do
    @organisation.name = nil

    refute @organisation.valid?
    assert_includes @organisation.errors.details[:name], error: :blank
  end

  test 'should be invalid if organisation_type_other is required but not defined' do
    organisation = organisations(:test_organisation_two)
    organisation.organisation_type_other = nil

    refute organisation.valid?
    assert_includes organisation.errors.details[:organisation_type_other], error: :blank
  end

  test 'should be invalid if organisation_type_other is defined but not required' do
    @organisation.organisation_type_other = 'Rawr!'

    refute @organisation.valid?
    assert_includes @organisation.errors.details[:organisation_type_other], error: :present
  end

  test 'should return the correct value for organisation_type_value' do
    organisation = organisations(:test_organisation_two)

    assert_equal organisation.organisation_type_other,  organisation.organisation_type_value
    assert_equal @organisation.organisation_type.value, @organisation.organisation_type_value
  end

  test 'should nullify empty strings before saving' do
    @organisation.add1 = 'Address1'
    @organisation.add2 = ''
    @organisation.save && @organisation.reload

    refute_nil @organisation.add1
    assert_nil @organisation.add2
  end

  test 'Can build polymorphic addresses for organisation' do
    @organisation.addresses.build(add1: 'test1')
    @organisation.addresses.build(add1: 'test2')
    assert @organisation.valid?
    @organisation.save && @organisation.reload
    assert_equal 2, @organisation.addresses.size
  end
end
