require 'test_helper'

class ContractTest < ActiveSupport::TestCase
  test 'should belong to a project' do
    project  = projects(:one)
    contract = project.contracts.build

    assert_equal project, contract.project
    assert_includes project.contracts, contract
  end

  test 'should be invalid without a project' do
    contract = Contract.new
    contract.valid?

    assert_includes contract.errors.details[:project], error: :blank

    contract.project = projects(:one)
    contract.valid?

    refute_includes contract.errors.details[:project], error: :blank
  end

  test 'should be associated with a project state' do
    project  = projects(:one)
    contract = create_contract(project)

    assert_equal project.current_project_state, contract.project_state
  end

  test 'should be invalid without an associated project_state' do
    contract = Contract.new
    contract.valid?

    assert_includes contract.errors.details[:project_state], error: :blank
  end

  test 'should be auditable' do
    project  = projects(:one)
    contract = project.contracts.build

    with_versioning do
      assert_auditable contract
    end
  end
end
