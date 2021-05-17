require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'validate password complexity - too short ' do
    user = build_and_validate_user(password: 'test')
    refute user.valid?, 'should be invalid: password too short'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - not complex ' do
    user = build_and_validate_user(password: 'testaaaa')
    refute user.valid?, 'should be invalid: password too short'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - no lowercase ' do
    user = build_and_validate_user(password: 'TEST1234*')
    refute user.valid?, 'should be invalid: no lowercase in password'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - no uppercase ' do
    user = build_and_validate_user(password: 'test1234*')
    refute user.valid?, 'should be invalid: no uppercase in password'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - not number ' do
    user = build_and_validate_user(password: 'TESTaaaa*')
    refute user.valid?, 'should be invalid: no number'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - not special char ' do
    user = build_and_validate_user(password: 'TESTaaaa')
    refute user.valid?, 'should be invalid: no special char'
    assert user.errors[:password].any?, 'is too short'
  end

  test 'validate password complexity - just right ' do
    user = build_and_validate_user(password: 'TESTaaa1*')
    assert user.valid?
    assert user.errors[:password].count, 0
  end

  test 'validate presence of email' do
    user = build_and_validate_user(email: '')
    refute user.valid?, 'should be invalid: no email'
    assert user.errors[:email].any?, 'email should have error when not present'
  end

  test 'validate presence of first name' do
    user = build_and_validate_user(first_name: '')
    refute user.valid?, 'should be invalid: no first_name'
    assert user.errors[:first_name].any?, 'first_name should have error when not present'
  end

  test 'validate presence of last name' do
    user = build_and_validate_user(last_name: '')
    refute user.valid?, 'should be invalid: no last_name'
    assert user.errors[:last_name].any?, 'last_name should have error when not present'
  end

  test 'validate presence of location' do
    skip

    user = build_and_validate_user(location: '')
    refute user.valid?, 'should be invalid: no location'
    assert user.errors[:location].any?, 'location should have error when not present'
  end

  test 'validate z_user_status_id' do
    skip

    user = build_and_validate_user(z_user_status_id: 'CABBAGE')
    refute user.valid?, 'should be invalid: incorrect z_user_status_id'
    assert user.errors[:z_user_status].any?
  end

  test 'validate teams' do
    user = build_and_validate_user(teams: [Team.new(name: 'CABBAGE')])
    refute user.valid?, 'should be invalid: team does not exist'
    assert user.errors[:teams].any?
  end

  test 'users flagged as deleted should not be active_for_authentication?' do
    user = build_and_validate_user
    assert user.active_for_authentication?, 'should be active for authentication'

    user.update!(z_user_status_id: ZUserStatus.where(name: 'Deleted').first.id)
    refute user.active_for_authentication?, 'should not be active for authentication'
  end

  test 'should flag user as administrator' do
    assert users(:admin_user).administrator?
    refute users(:standard_user).administrator?
  end

  test 'should flag user as standard' do
    user = users(:standard_user)

    assert user.standard?

    user.stubs(administrator?: true)
    refute user.standard?

    user.unstub(:administrator?)
    user.stubs(odr?: true)
    refute user.standard?

    user.unstub(:odr?)
    user.stubs(application_manager?: true)
    refute user.standard?

    user.unstub(:application_manager?)
    user.stubs(senior_application_manager?: true)
    refute user.standard?
  end

  test 'should flag as has_cas_roles' do
    user = users(:standard_user)
    refute user.cas_role?

    user.stubs(cas_dataset_approver?: true)
    assert user.cas_role?

    user.unstub(:cas_dataset_approver?)
    user.stubs(cas_access_approver?: true)
    assert user.cas_role?

    user.unstub(:cas_access_approver?)
    user.stubs(cas_manager?: true)
    assert user.cas_role?
  end

  test 'user has teams' do
    user = users(:standard_user2)
    assert user.teams?

    user = users(:standard_user_no_teams)
    refute user.teams?
  end

  test 'user status updated to locked when devise locks' do
    user = users(:standard_user)
    user.locked_at = DateTime.current
    user.save
    assert_equal ZUserStatus.where(name: 'Lockout').first.id, user.z_user_status_id
  end

  test 'get a list of administrators' do
    assert_equal User.administrators.count, 2
  end

  test 'get a list of odr users' do
    assert_equal User.odr_users.count, 2
  end

  test 'should not be invalid without username' do
    user = users(:standard_user)
    user.username = nil
    user.valid?

    assert_not_includes user.errors.details[:username], error: :blank
    assert_nothing_raised { user.save }
  end

  test 'should validate uniqueness of username' do
    User.where.not(id: User.administrators.or(User.odr_users)).
      update_all(username: nil)

    basic_user = users(:standard_user)
    admin_user = users(:admin_user)
    odr_user   = users(:odr_user)

    basic_user.valid?
    assert_not_includes basic_user.errors.details[:username], error: :taken

    odr_user.username = admin_user.username
    odr_user.valid?
    assert_includes odr_user.errors.details[:username], error: :taken, value: admin_user.username
  end

  test 'should decode object_guid' do
    user = users(:standard_user)
    user.object_guid = '6yC/cIZ1KEKDccGPKNB0nw=='

    assert_equal '70bf20eb-7586-4228-8371-c18f28d0749f', user.guid
  end

  test 'application_managers scope' do
    scope = User.application_managers

    assert_includes scope, users(:application_manager_one)
    refute_includes scope, users(:standard_user)
    refute_includes scope, users(:odr_user)
    refute_includes scope, users(:admin_user)
  end

  test 'should identify as an application manager' do
    application_manager     = users(:application_manager_one)
    not_application_manager = users(:standard_user)

    assert application_manager.application_manager?
    refute not_application_manager.application_manager?
  end

  test 'should identify external users' do
    user = users(:standard_user)

    user.email = 'someone@phe.gov.uk'
    refute user.external?

    user.email = 'someone@example.com'
    assert user.external?
  end

  test 'should lock external accounts' do
    user = users(:standard_user)

    assert_no_changes -> { user.locked_at } do
      user.update email: 'someone@phe.gov.uk'
      refute user.access_locked?
    end

    assert_changes -> { user.locked_at } do
      user.update email: 'someone@example.com'
      assert user.access_locked?
    end
  end

  test 'search scope is chainable' do
    assert_kind_of ActiveRecord::Relation, User.search
  end

  test 'search scope returns all with no parameters' do
    assert_equal User.all, User.search
  end

  test 'search scope filters on all criteria' do
    scope = User.search(
      params: { first_name: 'Application', last_name: 'Manager-One' }
    )

    assert_includes scope, users(:application_manager_one)
    refute_includes scope, users(:application_manager_two)
  end

  test 'search scope filter on any criteria' do
    scope = User.search(
      params: { first_name: 'Application', last_name: 'Manager-One' },
      greedy: false
    )

    assert_includes scope, users(:application_manager_one)
    assert_includes scope, users(:application_manager_two)
  end

  test 'search scope is case insensitive' do
    scope = User.search(
      params: { first_name: 'application', last_name: 'manager-One' }
    )

    assert_includes scope, users(:application_manager_one)
  end

  test 'search scope is fuzzy' do
    scope = User.search(
      params: { first_name: 'App', last_name: 'Manager-One' }
    )

    assert_includes scope, users(:application_manager_one)
  end
end
