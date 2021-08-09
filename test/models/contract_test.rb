require 'test_helper'

class ContractTest < ActiveSupport::TestCase
  def setup
    @data_released_project ||= projects(:test_application)
    %w[SUBMITTED DPIA_START DPIA_REVIEW DPIA_MODERATION CONTRACT_DRAFT
       CONTRACT_COMPLETED DATA_RELEASED].each do |state|
      Workflow::ProjectState.create!(state_id: state,
                                     project_id: @data_released_project.id,
                                     user_id: User.first.id)
    end
  end

  test 'should belong to a project' do
    project  = projects(:one)
    contract = project.global_contracts.build

    assert_equal project, contract.project
    assert_includes project.global_contracts, contract
  end

  test 'should be invalid without a project' do
    contract = Contract.new
    contract.valid?

    assert_includes contract.errors.details[:project], error: :blank

    contract.project = projects(:one)
    contract.valid?

    refute_includes contract.errors.details[:project], error: :blank
  end

  test 'should include BelongsToReferent' do
    assert_includes Contract.included_modules, BelongsToReferent
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
    contract = project.global_contracts.build

    with_versioning do
      assert_auditable contract
    end
  end

  test 'should not auto transition to data destroyed if a destruction date is not present' do
    assert_no_changes -> { @data_released_project.current_state } do
      build_contract(@data_released_project).save!
    end
  end

  test 'should auto transition to data destroyed if a any destruction date is present' do
    assert_changes -> { @data_released_project.current_state.id }, 'DATA_DESTROYED' do
      build_contract(@data_released_project) do |contract|
        contract.destruction_form_received_date = Date.current
        contract.save!
      end
    end
  end

  test 'should not auto transition to data destroyed if not in correct previous state' do
    @data_released_project.transition_to!(Workflow::State.find_by(id: 'AMEND'))
    assert_no_changes -> { @data_released_project.current_state } do
      build_contract(@data_released_project) do |contract|
        contract.destruction_form_received_date = Date.current
        contract.save!
      end
    end
  end

  private

  def build_contract(project, **attributes)
    project.global_contracts.build(referent: project, **attributes) do |contract|
      yield(contract) if block_given?
    end
  end
end
