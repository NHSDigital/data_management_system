require 'test_helper'

class AddressesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @team = teams(:team_one)
    @address1 = @team.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                                      postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                                      default_address: true)
    @address2 = @team.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                                      postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                                      default_address: false)
    User.any_instance.stubs(administrator?: true)
    @team.save
    @user = users(:standard_user2)
    sign_in(@user)
  end

  test 'should set all default_address values to false then set selected one to true' do
    patch default_address_url, params: { default_address: @address2.id,
                                         addressable_id: @address2.addressable_id,
                                         addressable_type: @address2.addressable_type }
    assert_redirected_to team_url(@team)
    assert @address1.reload.default_address == false
    assert @address2.reload.default_address == true
  end

  test 'should raise error if invalid Addressable_type passed' do
    assert_raise(RuntimeError) do
      patch default_address_url, params: { default_address: @address2.id,
                                           addressable_id: @address2.addressable_id,
                                           addressable_type: 'Cabbage' }
    end
  end
end
