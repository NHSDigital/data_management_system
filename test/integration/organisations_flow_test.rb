require 'test_helper'

class OrganisationsFlowsTest < ActionDispatch::IntegrationTest
  def setup
    @organisation = organisations(:test_organisation_one)

    sign_in users(:admin_user)
  end

  test 'should redirect if unauthorized' do
    sign_out :user
    sign_in users(:standard_user)

    visit edit_organisation_path(@organisation)

    assert_equal root_path, current_path
    assert page.has_text? 'You are not authorized to access this page'
  end

  test 'should be able to create organisations' do
    visit new_organisation_path
    assert_equal new_organisation_path, current_path

    fill_in :organisation_name, with: 'New Test Organisation'
    select 'Other', from: :organisation_organisation_type_id

    assert_no_difference('Organisation.count') do
      click_button 'Create Organisation'
    end

    assert page.has_text?(/\d+ errors? prevented this record from being saved/)

    fill_in :organisation_organisation_type_other, with: 'Council of Nightmares'

    assert_difference('Organisation.count') do
      click_button 'Create Organisation'
    end

    new_organisation = Organisation.order(:created_at).last

    assert_equal organisation_path(new_organisation), current_path
    assert page.has_text? 'Organisation was successfully created.'
  end

  test 'should be able to update organisations' do
    visit edit_organisation_path(@organisation)
    assert_equal edit_organisation_path(@organisation), current_path

    fill_in :organisation_name, with: ''

    assert_no_changes -> { @organisation.reload.name } do
      assert_no_changes -> { @organisation.reload.add1 } do
        click_button 'Update Organisation'
      end
    end

    assert page.has_text?(/\d+ errors? prevented this record from being saved/)

    fill_in :organisation_name, with: 'Test Org #1'

    assert_changes -> { @organisation.reload.name } do
      click_button 'Update Organisation'
    end

    assert_equal organisation_path(@organisation), current_path
    assert page.has_text? 'Organisation was successfully updated.'
  end

  # TODO - Clarify what happens when destroying an organisation, particulary if any organisation
  # teams have active projects...
  test 'should be able to destroy organisations' do
    skip
    visit organisations_path

    assert_difference 'Organisation.count', -1 do
      accept_alert do
        click_link title: 'Delete', href: organisation_path(@organisation)
      end
    end

    assert_equal organisations_path, current_path
    assert page.has_text? 'Organisation was successfully destroyed.'
  end

  test 'can create organisation with addresses' do
    visit new_organisation_path
    assert_equal new_organisation_path, current_path

    fill_in :organisation_name, with: 'Hammond Organ'
    select 'Other', from: :organisation_organisation_type_id
    fill_in :organisation_organisation_type_other, with: 'Keyboards'
    click_on 'Add Address'

    fill_in 'Add1', with: 'Address Line 1'
    fill_in 'Add2', with: 'Address Line 2'
    fill_in 'City', with: 'Sim'
    fill_in 'Telephone', with: '1234567'
    fill_in 'Postcode', with: 'AB1 2CD'
    assert_difference('Organisation.count') do
      assert_difference('Address.count') do
        click_button 'Create Organisation'
      end
    end
  end

  test 'should be able to search for resources' do
    visit organisations_path

    within('#search-form') do
      fill_in 'search[name]', with: 'one'
      click_button :submit
    end

    assert_equal organisations_path, current_path

    within('table') do
      assert has_text?('Test Organisation One')
      refute has_text?('Test Organisation Two')
    end
  end
end
