require 'test_helper'

class AddressHelperTest < ActionView::TestCase
  test 'address_tag' do
    organisation = organisations(:test_organisation_one)
    organisation.addresses.build(add1: 'Address1', add2: 'Address2',
                                 city: 'Somewhere', postcode: 'ZZ99 9ZZ',
                                 country_id: Lookups::Country.find_by(value: 'UNITED KINGDOM').id)
    organisation.save! && organisation.reload

    expected     = '<address>Address1<br />Address2<br />Somewhere<br />' \
                   'ZZ99 9ZZ<br />UNITED KINGDOM</address>'

    assert_dom_equal expected, address_tag(organisation)
  end
end
