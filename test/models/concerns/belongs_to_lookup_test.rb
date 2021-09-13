require 'test_helper'

# Tests the BelongsToLookup concern
class BelongsToLookupTest < ActiveSupport::TestCase
  def setup
    @release = Release.new(
      project:  projects(:dummy_project),
      referent: projects(:dummy_project)
    )
  end

  test 'belongs_to_lookup should allow valid value' do
    @release.vat_reg = 'Y'
    @release.valid?

    assert_empty @release.errors.details[:vat_reg]
  end

  test 'belongs_to_lookup should add error on invalid value' do
    @release.vat_reg = 'Z'
    @release.valid?

    assert_includes @release.errors.details[:vat_reg], error: :lookup
  end

  test 'belongs_to_lookup with a scoped association' do
    @release.income_received = 'NA'
    @release.valid?

    assert_includes @release.errors.details[:income_received], error: :lookup

    @release.income_received = 'Y'
    @release.valid?
    refute_includes @release.errors.details[:income_received], error: :lookup
  end

  test 'should nullify blank values to avoid foreign key errors' do
    @release.income_received = ''

    assert_nothing_raised do
      @release.save(validate: false)

      assert_nil @release.income_received
    end
  end

  # TODO:
  # test 'belongs_to_lookup should detect when typecasting may erroneously store zeroes' do
  #   skip
  # end
end
