require 'test_helper'

class AddressTest < ActionDispatch::IntegrationTest
  def setup
    @admin        = users(:admin_user)
    @organisation = organisations(:test_organisation_one)
    @team = teams(:team_one)

    login_and_accept_terms(@admin)
  end

  test 'all addresses should be displayed for an organisation' do
    visit organisation_path(@organisation)

    assert has_no_content?('Primary Address')
    assert has_no_content?('other addresses')

    # for purposes of this test set default_address to true
    @organisation.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                                  postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                                  default_address: true)
    @organisation.save
    visit organisation_path(@organisation)

    assert has_content?('Primary Address')
    assert has_content?('add1_test')
    assert has_content?('add2_test')
    assert has_content?('city_test')
    assert has_content?('T3ST1NG')
    assert has_content?('01234')
    assert has_content?('UNITED KINGDOM')
    assert has_no_content?('other addresses')

    @organisation.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                                  postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                                  default_address: false)
    @organisation.save
    visit organisation_path(@organisation)

    assert has_content?('other addresses')
    click_link('other addresses')

    assert has_content?('hide')
    assert has_no_content?('other addresses')

    within("#organisation_#{@organisation.id}_addresses") do
      assert has_content?('set as default address')
      assert has_no_content?('Primary Address')
      assert has_content?('add1_test2')
      assert has_content?('add2_test2')
      assert has_content?('city_test2')
      assert has_content?('T3ST1NG2')
      assert has_content?('43210')
      assert has_content?('ANTARCTICA')
    end
  end

  test 'should be able to change default address for organisation' do
    @organisation.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                                  postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                                  default_address: false)
    @organisation.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                                  postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                                  default_address: true)
    @organisation.save
    visit organisation_path(@organisation)

    assert has_no_content?('Other Addresses')
    assert has_content?('Primary Address')
    assert has_content?('T3ST1NG2')

    click_link('other addresses')

    address1 = Address.find_by(postcode: 'T3ST1NG')

    within("#address_#{address1.id}") do
      click_link('set as default address')
    end

    address1.reload
    assert address1.default_address == true
    assert Address.find_by(postcode: 'T3ST1NG2').default_address == false

    assert has_content?('Default address updated')
    assert has_no_content?('Other Addresses')
    assert has_content?('Primary Address')
    assert has_content?('T3ST1NG')
  end

  test 'if no org default address is set display primary address as most recent address added' do
    @organisation.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                                  postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                                  default_address: false)
    @organisation.save
    @organisation.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                                  postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                                  default_address: true)
    @organisation.save
    visit organisation_path(@organisation)

    within('#default_address') do
      assert has_content?('add1_test2')
      assert has_content?('add2_test2')
      assert has_content?('city_test2')
      assert has_content?('T3ST1NG2')
      assert has_content?('43210')
      assert has_content?('ANTARCTICA')
    end
  end

  test 'all addresses should be displayed for a team' do
    visit team_path(@team)

    assert has_no_content?('Primary Address')
    assert has_no_content?('other addresses')

    # for purposes of this test set default_address to true
    @team.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                          postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                          default_address: true)
    @team.save
    visit team_path(@team)

    assert has_content?('Primary Address')
    assert has_content?('add1_test')
    assert has_content?('add2_test')
    assert has_content?('city_test')
    assert has_content?('T3ST1NG')
    assert has_content?('01234')
    assert has_content?('UNITED KINGDOM')
    assert has_no_content?('other addresses')

    @team.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                          postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                          default_address: false)
    @team.save
    visit team_path(@team)

    assert has_content?('other addresses')
    click_link('other addresses')
    assert has_content?('hide')
    assert has_no_content?('other addresses')

    within("#team_#{@team.id}_addresses") do
      assert has_content?('set as default address')
      assert has_no_content?('Primary Address')
      assert has_content?('add1_test2')
      assert has_content?('add2_test2')
      assert has_content?('city_test2')
      assert has_content?('T3ST1NG2')
      assert has_content?('43210')
      assert has_content?('ANTARCTICA')
    end
  end

  test 'should be able to change default address for team' do
    @team.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                          postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                          default_address: false)
    @team.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                          postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                          default_address: true)
    @team.save
    visit team_path(@team)

    assert has_no_content?('Other Addresses')
    assert has_content?('Primary Address')
    assert has_content?('T3ST1NG2')

    click_link('other addresses')

    address1 = Address.find_by(postcode: 'T3ST1NG')

    within("#address_#{address1.id}") do
      click_link('set as default address')
    end

    address1.reload
    assert address1.default_address == true
    assert Address.find_by(postcode: 'T3ST1NG2').default_address == false

    assert has_content?('Default address updated')
    assert has_no_content?('Other Addresses')
    assert has_content?('Primary Address')
    assert has_content?('T3ST1NG')
  end

  test 'if no team default address is set display primary address as most recent address added' do
    @team.addresses.build(add1: 'add1_test', add2: 'add2_test', city: 'city_test',
                          postcode: 'T3ST1NG', telephone: '01234', country_id: 'XKU',
                          default_address: false)
    @team.save
    @team.addresses.build(add1: 'add1_test2', add2: 'add2_test2', city: 'city_test2',
                          postcode: 'T3ST1NG2', telephone: '43210', country_id: 'ATA',
                          default_address: true)
    @team.save
    visit team_path(@team)

    within('#default_address') do
      assert has_content?('add1_test2')
      assert has_content?('add2_test2')
      assert has_content?('city_test2')
      assert has_content?('T3ST1NG2')
      assert has_content?('43210')
      assert has_content?('ANTARCTICA')
    end
  end
end
