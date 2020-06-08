require 'test_helper'

class AbilityOdrApplicationTest < ActiveSupport::TestCase
  def setup
    @applicant = create_user(username: 'odr_applicant',
                             email: 'ability_odr_applicant@phe.gov.uk',
                             first_name: 'ability',
                             last_name: 'odr_applicant')

    @project = create_project(project_type: project_types(:application),
                              project_purpose: 'odr ablity',
                              owner: @applicant)
    @project.reload_current_state
    Grant.create!(team: @project.team, user: @applicant,
                  roleable: TeamRole.fetch(:odr_applicant))
    @applicant_ablity = Ability.new(@applicant)
  end

  test 'odr_applicant can edit application in draft state' do
    refute @applicant_ablity.can? :create, Project.new
    assert @applicant_ablity.can? :create, Project.new(team: @project.team)
    assert @applicant_ablity.can? :duplicate, @project
    assert @applicant_ablity.can? :destroy, @project
    assert @applicant_ablity.can? :read, @project
    assert @applicant_ablity.can? :update, @project
    assert @applicant_ablity.can? :edit_data_source_items, @project

    @project.transition_to(Workflow::State.find('SUBMITTED'))
    @project.reload_current_state

    assert @applicant_ablity.can? :duplicate, @project
    refute @applicant_ablity.can? :destroy, @project
    assert @applicant_ablity.can? :read, @project
    refute @applicant_ablity.can? :update, @project
    refute @applicant_ablity.can? :edit_data_source_items, @project
  end
end
