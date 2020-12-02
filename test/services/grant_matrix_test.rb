require 'test_helper'

class GrantMatrixTest < ActiveSupport::TestCase
  test 'team params correctly cleaned' do
    test_params = { 'TeamRole' =>
                    { teams(:team_one).id => { team_roles(:role_one).id => '',
                                               team_roles(:role_two).id => '',
                                               team_roles(:role_three).id => '1' },
                      teams(:team_two).id => { team_roles(:role_one).id => '1',
                                               team_roles(:role_two).id => '1',
                                               team_roles(:role_three).id => '1' } } }

    matrix = GrantMatrix.new({})
    matrix.send(:clean_up!, test_params)
    clean_params = matrix.grant_hash(test_params)

    assert clean_params.is_a? Hash
    assert_equal 6, clean_params.length, 'unexpected number of parameters for team grant params'
    transformed_keys = clean_params.keys.flat_map(&:keys).uniq.sort
    assert_equal transformed_keys, %i[roleable_id roleable_type team_id]
    assert_equal clean_params.values, [false, false, true, true, true, true]
  end

  test 'project params correctly cleaned' do
    test_params = { 'ProjectRole' =>
                    { projects(:one).id => { project_roles(:role_one).id => '1',
                                             project_roles(:role_two).id => '',
                                             project_roles(:role_three).id => '1' },
                      projects(:two).id => { project_roles(:role_one).id => '',
                                             project_roles(:role_two).id => '1',
                                             project_roles(:role_three).id => '1' } } }

    matrix = GrantMatrix.new({})
    matrix.send(:clean_up!, test_params)
    clean_params = matrix.grant_hash(test_params)

    assert clean_params.is_a? Hash
    assert_equal 6, clean_params.length, 'unexpected number of parameters for project grant params'
    transformed_keys = clean_params.keys.flat_map(&:keys).uniq.sort
    assert_equal transformed_keys, %i[project_id roleable_id roleable_type]
    assert_equal clean_params.values, [true, false, true, false, true, true]
  end

  test 'system params correctly cleaned' do
    sys_roles = { system_roles(:developer).id => '1',
                  system_roles(:odr_application_manager).id => '1',
                  system_roles(:odr).id => '' }
    test_params = { 'SystemRole' => { 'system' => sys_roles } }

    matrix = GrantMatrix.new({})
    matrix.send(:clean_up!, test_params)
    clean_params = matrix.grant_hash(test_params)

    assert clean_params.is_a? Hash
    assert_equal 3, clean_params.length, 'unexpected number of parameters for system grant params'
    transformed_keys = clean_params.keys.flat_map(&:keys).uniq.sort
    assert_equal transformed_keys, %i[roleable_id roleable_type]
    assert_equal clean_params.values, [true, true, false]
  end

  test 'dataset params correctly cleaned' do
    cas_dataset_one = Dataset.find_by(name: 'Extra CAS Dataset One')
    cas_dataset_two = Dataset.find_by(name: 'Extra CAS Dataset Two')
    test_params = { 'DatasetRole' =>
                    { cas_dataset_one.id => { dataset_roles(:approver).id => '1',
                                              dataset_roles(:not_approver).id => '1' },
                      cas_dataset_two.id => { dataset_roles(:approver).id => '',
                                              dataset_roles(:not_approver).id => '1' } } }

    matrix = GrantMatrix.new({})
    matrix.send(:clean_up!, test_params)
    clean_params = matrix.grant_hash(test_params)

    assert clean_params.is_a? Hash
    assert_equal 4, clean_params.length, 'unexpected number of parameters for project grant params'
    transformed_keys = clean_params.keys.flat_map(&:keys).uniq.sort
    assert_equal transformed_keys, %i[dataset_id roleable_id roleable_type]
    assert_equal clean_params.values, [true, true, false, true]
  end
end
