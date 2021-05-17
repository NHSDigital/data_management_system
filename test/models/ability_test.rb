require 'test_helper'

# FIXME: I think this needs a bit of attention, particularly anything relating to `Project`s and
# the models that exist below it in the model heirarchy. It would be advantageous to have coverage
# of each grant for each "role", without bumping into cross team membership issues (but the current
# fixtures are/appear somewhat tangled).
class AbilityTest < ActiveSupport::TestCase
  def setup
    # senior member of @team
    @senior_team_member = users(:standard_user1)
    @senior_team_member_ability = Ability.new(@senior_team_member)
    # non senior member of @other_team
    @non_senior_team_member = users(:standard_user_one_team)
    @non_senior_team_member_ability = Ability.new(@non_senior_team_member)

    @contributor = users(:contributor)
    @contributor_ability = Ability.new(@contributor)

    @admin = users(:admin_user)
    @admin_ability = Ability.new(@admin)

    @odr = users(:odr_user)
    @odr_ability = Ability.new(@odr)

    @team = teams(:team_one)
    @other_team = teams(:team_ONE_member)

    @project = projects(:one)
    # non senior member of @project
    @non_senior_project_member = users(:standard_user2)
    @non_senior_project_member_ability = Ability.new(@non_senior_project_member)
    @project_node = project_node(:one)

    @other_project = projects(:two)
    # senior member of @other_project
    @senior_project_member = users(:senior_project_user)
    @senior_project_member_ability = Ability.new(@senior_project_member)
    @other_project_node = project_node(:two)
    @dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    @dataset_version = @dataset.dataset_versions.find_by(semver_version: '1.0')
    @node = @dataset_version.data_items.first

    @application_manager_ability = Ability.new(users(:application_manager_one))
    dataset_manager_setup

    @no_roles = users(:no_roles)
    @no_roles_ability = Ability.new(@no_roles)
  end

  test 'team grants' do
    refute @senior_team_member_ability.can? :create, Team.new
    assert @senior_team_member_ability.can? :read, @team
    refute @senior_team_member_ability.can? :update, @team
    refute @senior_team_member_ability.can? :destroy, @team

    refute @senior_team_member_ability.can? :read, @other_team
    refute @senior_team_member_ability.can? :update, @other_team
    refute @senior_team_member_ability.can? :destroy, @other_team

    refute @non_senior_team_member_ability.can? :create, Team.new
    refute @non_senior_team_member_ability.can? :read, @team
    refute @non_senior_team_member_ability.can? :update, @team
    refute @non_senior_team_member_ability.can? :destroy, @team

    assert @non_senior_team_member_ability.can? :read, @other_team
    refute @non_senior_team_member_ability.can? :update, @other_team
    refute @non_senior_team_member_ability.can? :destroy, @other_team
  end

  test 'membership grants' do
    assert @senior_team_member_ability.can? :create, Project.new(team: @team)

    refute @senior_team_member_ability.can? :create, Grant.new
    # refute @senior_team_member_ability.can? :create, Membership.new
    # TODO: fix me. is this testing a senior user, (now owner) can add a user to a team?
    # assert @senior_team_member_ability.can? :create, Membership.new(team: @team)
    # assert @senior_team_member_ability.can? :update, @team_membership
    # assert @senior_team_member_ability.can? :destroy, @team_membership

    # refute @senior_team_member_ability.can? :create, Membership.new(team: @other_team)
    # refute @senior_team_member_ability.can? :update, @other_team_membership
    # refute @senior_team_member_ability.can? :destroy, @other_team_membership

    refute @non_senior_team_member_ability.can? :create, Project.new(team: @team)
    refute @non_senior_team_member_ability.can? :create, Grant.new
    # refute @non_senior_team_member_ability.can? :create, Membership.new(team: @team)
    # refute @non_senior_team_member_ability.can? :update, @team_membership
    # refute @non_senior_team_member_ability.can? :destroy, @team_membership

    # refute @non_senior_team_member_ability.can? :create, Membership.new(team: @other_team)
    # refute @non_senior_team_member_ability.can? :update, @other_team_membership
    # refute @non_senior_team_member_ability.can? :destroy, @other_team_membership
  end

  test 'project grants' do
    refute @senior_project_member_ability.can? :create, Project.new
    # refute @senior_project_member_ability.can? :destroy, @other_project
    assert @senior_project_member_ability.can? :read, @other_project
    refute @senior_project_member_ability.can? :update, @other_project
    # eh? A senior user can't update project but can edit these?
    # assert @senior_project_member_ability.can? :edit_ons_data_access, @other_project
    # assert @senior_project_member_ability.can? :edit_ons_declaration, @other_project
    # assert @senior_project_member_ability.can? :edit_data_source_items, @other_project
    refute @senior_project_member_ability.can? :edit_ons_data_access, @other_project
    refute @senior_project_member_ability.can? :edit_ons_declaration, @other_project
    refute @senior_project_member_ability.can? :edit_data_source_items, @other_project
    assert @senior_project_member_ability.can? :show_ons_declaration_use, @other_project
    assert @senior_project_member_ability.can? :show_ons_declaration_list, @other_project
    assert @senior_project_member_ability.can? :show_ons_access_agreement, @other_project
    # assert @senior_project_member_ability.can? :submit, @other_project

    refute @senior_project_member_ability.can? :destroy, @project
    refute @senior_project_member_ability.can? :read, @project
    refute @senior_project_member_ability.can? :update, @project
    refute @senior_project_member_ability.can? :edit_ons_data_access, @project
    refute @senior_project_member_ability.can? :edit_ons_declaration, @project
    refute @senior_project_member_ability.can? :edit_data_source_items, @project
    refute @senior_project_member_ability.can? :show_ons_declaration_use, @project
    refute @senior_project_member_ability.can? :show_ons_declaration_list, @project
    refute @senior_project_member_ability.can? :show_ons_access_agreement, @project
    # refute @senior_project_member_ability.can? :submit, @project

    refute @non_senior_project_member_ability.can? :create, Project.new
    refute @non_senior_project_member_ability.can? :destroy, @other_project
    refute @non_senior_project_member_ability.can? :read, @other_project
    refute @non_senior_project_member_ability.can? :update, @other_project
    refute @non_senior_project_member_ability.can? :edit_ons_data_access, @other_project
    refute @non_senior_project_member_ability.can? :edit_ons_declaration, @other_project
    refute @non_senior_project_member_ability.can? :edit_data_source_items, @other_project
    refute @non_senior_project_member_ability.can? :show_ons_declaration_use, @other_project
    refute @non_senior_project_member_ability.can? :show_ons_declaration_list, @other_project
    refute @non_senior_project_member_ability.can? :show_ons_access_agreement, @other_project
    # refute @non_senior_project_member_ability.can? :submit, @other_project

    assert @non_senior_project_member_ability.can? :read, @project
    refute @non_senior_project_member_ability.can? :update, @project
    refute @non_senior_project_member_ability.can? :edit_ons_data_access, @project
    refute @non_senior_project_member_ability.can? :edit_ons_declaration, @project
    refute @non_senior_project_member_ability.can? :edit_data_source_items, @project
    assert @non_senior_project_member_ability.can? :show_ons_declaration_use, @project
    assert @non_senior_project_member_ability.can? :show_ons_declaration_list, @project
    assert @non_senior_project_member_ability.can? :show_ons_access_agreement, @project
    # refute @non_senior_project_member_ability.can? :submit, @project

    assert @senior_team_member_ability.cannot?(:approve, @project)
    assert @non_senior_team_member_ability.cannot?(:approve, @project)
    assert @non_senior_team_member_ability.cannot?(:approve_members, @project)
  end

  test 'project assign grant' do
    team_one            = teams(:team_one)
    team_delegate       = users(:delegate_user1)
    project_member      = users(:standard_user1)
    project_senior      = users(:standard_user2)
    other_user          = users(:standard_user)
    application_manager = users(:application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    project = build_project(
      team: team_one,
      assigned_user: application_manager
    )
    project.save!

    # add Senior user grant (Applicant)
    ro_grant = Grant.new(user: project_member, roleable: ProjectRole.fetch(:read_only))
    project.reload
    project.grants << ro_grant
    project.save!
    # project.project_memberships.create!(
    #   membership: team_one.memberships.find_or_create_by(member: project_member)
    # )

    refute project_member.can?      :assign, project
    refute project_senior.can?      :assign, project
    refute team_delegate.can?       :assign, project
    refute other_user.can?          :assign, project
    assert application_manager.can? :assign, project
    assert odr_user.can?            :assign, project
    refute admin_user.can?          :assign, project
  end

  # TODO: convert to grants
  # test 'project membership grants' do
  #   refute @senior_project_member_ability.can? :create, ProjectMembership.new
  #   refute @senior_project_member_ability.can? :create,
  #                                              ProjectMembership.new(project: @other_project)
  #   refute @senior_project_member_ability.can? :destroy, @other_project_membership
  #   refute @senior_project_member_ability.can? :update, @other_project_membership
  #
  #   refute @senior_project_member_ability.can? :create, ProjectMembership.new(project: @project)
  #   refute @senior_project_member_ability.can? :destroy, @project_membership
  #   refute @senior_project_member_ability.can? :update, @project_membership
  #
  #   refute @non_senior_project_member_ability.can? :create, ProjectMembership.new
  #   refute @non_senior_project_member_ability.can? :create,
  #                                                  ProjectMembership.new(project: @other_project)
  #   refute @non_senior_project_member_ability.can? :destroy, @other_project_membership
  #   refute @non_senior_project_member_ability.can? :update, @other_project_membership
  #
  #   refute @non_senior_project_member_ability.can? :create,
  #                                                  ProjectMembership.new(project: @project)
  #   refute @non_senior_project_member_ability.can? :destroy, @project_membership
  #   refute @non_senior_project_member_ability.can? :update, @project_membership
  #
  #   assert @senior_team_member_ability.cannot?(:approve, @project)
  #   assert @non_senior_team_member_ability.cannot?(:approve, @project)
  # end

  test 'project data source item grants' do
    refute @senior_project_member_ability.can? :create, ProjectNode.new
    refute @senior_project_member_ability.can? :create,
                                               ProjectNode.new(project: @other_project)
    refute @senior_project_member_ability.can? :destroy, @other_project_node
    refute @senior_project_member_ability.can? :update, @other_project_node

    refute @senior_project_member_ability.can? :create,
                                               ProjectNode.new(project: @project)
    refute @senior_project_member_ability.can? :destroy, @project_node
    refute @senior_project_member_ability.can? :update, @project_node

    refute @non_senior_project_member_ability.can? :create, ProjectNode.new
    refute @non_senior_project_member_ability.can? :create,
                                                   ProjectNode.new(
                                                     project: @other_project
                                                   )
    refute @non_senior_project_member_ability.can? :destroy, @other_project_node
    refute @non_senior_project_member_ability.can? :update, @other_project_node

    refute @non_senior_project_member_ability.can? :create,
                                                   ProjectNode.new(project: @project)
    refute @non_senior_project_member_ability.can? :destroy, @project_node
    refute @non_senior_project_member_ability.can? :update, @project_node
  end

  test 'admin user can manage all EXCEPT approvals' do
    assert @admin_ability.can? :create, Team.new
    assert @admin_ability.can? :read, @team
    assert @admin_ability.can? :update, @team
    assert @admin_ability.can? :destroy, @team
    assert @admin_ability.can? :read, @other_team
    assert @admin_ability.can? :update, @other_team
    assert @admin_ability.can? :destroy, @other_team

    @user = User.new
    assert @admin_ability.can? :create, User.new
    assert @admin_ability.can? :read, @user
    assert @admin_ability.can? :update, @user
    assert @admin_ability.can? :destroy, @user
    assert @admin_ability.can? :read, @admin
    assert @admin_ability.can? :update, @admin
    assert @admin_ability.can? :destroy, @admin

    assert @admin_ability.cannot? :create, Project.new
    assert @admin_ability.cannot? :create, Project.new(team: @team)
    assert @admin_ability.cannot? :create, Project.new(team: @other_team)
    assert @admin_ability.can? :read, @project
    assert @admin_ability.cannot? :update, @project
    assert @admin_ability.cannot? :destroy, @project

    assert @admin_ability.cannot?(:approve, @project)
    assert @admin_ability.cannot?(:approve_members, @project)

    assert @admin_ability.can? :create, Nodes::DataItem.new(dataset_version: @dataset_version)
    assert @admin_ability.can? :update, @node
    assert @admin_ability.can? :destroy, @node
    assert @admin_ability.can? :edit_system_grants, User
    assert @admin_ability.can? :edit_team_grants, User
    assert @admin_ability.can? :edit_project_grants, User
  end

  test 'odr grants' do
    assert @odr_ability.can?(:approve, @project)
    assert @odr_ability.can?(:approve_members, @project)
    assert @odr_ability.can?(:read, @project)
    assert @odr_ability.can?(:approve_details, @project)
    assert @odr_ability.can?(:reset_project_approvals, @project)
    assert @odr_ability.can?(:odr_submit_project_approvals, @project)
    refute @odr_ability.can?(:update, @project)
    refute @odr_ability.can?(:destroy, @project)
    assert @odr_ability.can?(:read, @senior_team_member)
    refute @odr_ability.can?(:update, @senior_team_member)
    refute @odr_ability.can?(:destroy, @senior_team_member)
    assert @odr_ability.can?(:read, @team)
    refute @odr_ability.can?(:update, @team)
    refute @odr_ability.can?(:destroy, @team)
  end

  test 'organisation grants' do
    organisation_one = organisations(:test_organisation_one)
    organisation_two = organisations(:test_organisation_two)

    assert @non_senior_team_member_ability.can? :read,    Organisation
    assert @non_senior_team_member_ability.can? :read,    organisation_one
    refute @non_senior_team_member_ability.can? :read,    organisation_two
    refute @non_senior_team_member_ability.can? :create,  organisation_one
    refute @non_senior_team_member_ability.can? :create,  organisation_two
    refute @non_senior_team_member_ability.can? :edit,    organisation_one
    refute @non_senior_team_member_ability.can? :edit,    organisation_two
    refute @non_senior_team_member_ability.can? :destroy, organisation_one
    refute @non_senior_team_member_ability.can? :destroy, organisation_two

    assert @senior_team_member_ability.can? :read,    Organisation
    assert @senior_team_member_ability.can? :read,    organisation_one
    refute @senior_team_member_ability.can? :read,    organisation_two
    refute @senior_team_member_ability.can? :create,  organisation_one
    refute @senior_team_member_ability.can? :create,  organisation_two
    refute @senior_team_member_ability.can? :edit,    organisation_one
    refute @senior_team_member_ability.can? :edit,    organisation_two
    refute @senior_team_member_ability.can? :destroy, organisation_one
    refute @senior_team_member_ability.can? :destroy, organisation_two

    assert @odr_ability.can? :read,    Organisation
    assert @odr_ability.can? :read,    organisation_one
    assert @odr_ability.can? :read,    organisation_two
    refute @odr_ability.can? :create,  organisation_one
    refute @odr_ability.can? :create,  organisation_two
    refute @odr_ability.can? :edit,    organisation_one
    refute @odr_ability.can? :edit,    organisation_two
    refute @odr_ability.can? :destroy, organisation_one
    refute @odr_ability.can? :destroy, organisation_two

    assert @admin_ability.can? :read,    Organisation
    assert @admin_ability.can? :read,    organisation_one
    assert @admin_ability.can? :create,  organisation_one
    assert @admin_ability.can? :edit,    organisation_one
    assert @admin_ability.can? :destroy, organisation_one
  end

  test 'ndr_error grants' do
    standard_user       = users(:standard_user)
    delegate_user       = users(:delegate_user1)
    application_manager = users(:application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    refute standard_user.can?       :read, :ndr_errors
    refute delegate_user.can?       :read, :ndr_errors
    refute application_manager.can? :read, :ndr_errors
    refute odr_user.can?            :read, :ndr_errors
    refute admin_user.can?          :read, :ndr_errors

    refute standard_user.can?       :edit, :ndr_errors
    refute delegate_user.can?       :edit, :ndr_errors
    refute application_manager.can? :edit, :ndr_errors
    refute odr_user.can?            :edit, :ndr_errors
    refute admin_user.can?          :edit, :ndr_errors
  end

  test 'user views' do
    assert @senior_team_member_ability.can? :teams, User
    assert @senior_team_member_ability.can? :projects, User
    refute @senior_team_member_ability.can? :edit_system_grants, User
    refute @senior_team_member_ability.can? :edit_team_grants, User
    refute @senior_team_member_ability.can? :edit_project_grants, User
  end

  test 'application manager grants' do
    assert @application_manager_ability.can? :edit_grants, User
    refute @application_manager_ability.can? :edit_system_grants, User
    assert @application_manager_ability.can? :edit_team_grants, User
    assert @application_manager_ability.can? :edit_project_grants, User
    assert @application_manager_ability.can? :create, Organisation
    assert @application_manager_ability.can? :create, Directorate
    assert @application_manager_ability.can? :create, Division
    assert @application_manager_ability.can? :create, Team
    assert @application_manager_ability.can? :create, Project
  end

  test 'project dataset' do
    ProjectDataset.where(project: @project).each do |project_dataset|
      assert @senior_team_member_ability.can?     :read, project_dataset
      assert @contributor.can?                    :read, project_dataset
      assert users(:delegate_user1).can?          :read, project_dataset
      assert users(:application_manager_one).can? :read, project_dataset
      assert users(:odr_user).can?                :read, project_dataset
      assert users(:admin_user).can?              :read, project_dataset
    end
  end

  test 'project node' do
    ProjectNode.where(project: @project).each do |project_node|
      assert @senior_team_member_ability.can?     :read, project_node
      assert @contributor.can?                    :read, project_node
      assert users(:delegate_user1).can?          :read, project_node
      assert users(:application_manager_one).can? :read, project_node
      assert users(:odr_user).can?                :read, project_node
      assert users(:admin_user).can?              :read, project_node
    end
  end

  test 'project end use' do
    @project.end_uses << end_uses(:one)
    ProjectEndUse.where(project: @project).each do |project_end_use|
      assert @senior_team_member_ability.can?     :read, project_end_use
      assert @contributor.can?                    :read, project_end_use
      assert users(:delegate_user1).can?          :read, project_end_use
      assert users(:application_manager_one).can? :read, project_end_use
      assert users(:odr_user).can?                :read, project_end_use
      assert users(:admin_user).can?              :read, project_end_use
    end
  end

  test 'project classification' do
    @project.classifications << classifications(:one)
    ProjectEndUse.where(project: @project).each do |project_classification|
      assert @senior_team_member_ability.can?     :read, project_classification
      assert @contributor.can?                    :read, project_classification
      assert users(:delegate_user1).can?          :read, project_classification
      assert users(:application_manager_one).can? :read, project_classification
      assert users(:odr_user).can?                :read, project_classification
      assert users(:admin_user).can?              :read, project_classification
    end
  end

  test 'project lawful basis' do
    @project.lawful_bases << Lookups::LawfulBasis.first
    ProjectEndUse.where(project: @project).each do |project_lawful_basis|
      assert @senior_team_member_ability.can?     :read, project_lawful_basis
      assert @contributor.can?                    :read, project_lawful_basis
      assert users(:delegate_user1).can?          :read, project_lawful_basis
      assert users(:application_manager_one).can? :read, project_lawful_basis
      assert users(:odr_user).can?                :read, project_lawful_basis
      assert users(:admin_user).can?              :read, project_lawful_basis
    end
  end

  test 'dataset' do
    assert @senior_team_member_ability.can? :read, Dataset
    assert @senior_team_member_ability.can? :read, DatasetVersion
    assert @senior_team_member_ability.can? :read, Node
    assert @senior_team_member_ability.can? :read, Category
    assert @senior_team_member_ability.cannot? :update, Dataset
    assert @senior_team_member_ability.cannot? :update, DatasetVersion
    assert @senior_team_member_ability.cannot? :update, Node
    assert @senior_team_member_ability.cannot? :update, Category

    assert @application_manager_ability.can? :read, Dataset
    assert @application_manager_ability.can? :read, DatasetVersion
    assert @application_manager_ability.can? :read, Node
    assert @application_manager_ability.can? :read, Category
    assert @application_manager_ability.cannot? :update, Dataset
    assert @application_manager_ability.cannot? :update, DatasetVersion
    assert @application_manager_ability.cannot? :update, Node
    assert @application_manager_ability.cannot? :update, Category

    assert @admin.can? :read, Dataset
    assert @admin.can? :read, DatasetVersion
    assert @admin.can? :read, Node
    assert @admin.can? :read, Category
    assert @admin.can? :update, Dataset
    assert @admin.can? :update, DatasetVersion
    assert @admin.can? :update, Node
    assert @admin.can? :update, Category
  end

  test 'dataset version abilities' do
    assert @admin.can? :download, DatasetVersion
    assert @admin.can? :publish, DatasetVersion
    assert @senior_team_member_ability.can? :download, DatasetVersion
    assert @senior_team_member_ability.cannot? :publish, DatasetVersion
    assert @application_manager_ability.can? :download, DatasetVersion
    assert @application_manager_ability.cannot? :publish, DatasetVersion
    assert @non_senior_team_member_ability.can? :download, DatasetVersion
    assert @non_senior_team_member_ability.cannot? :publish, DatasetVersion
  end

  test 'user update abilities' do
    assert @admin.can? :update, @no_roles
    # should be able to update own user details
    assert @no_roles_ability.can? :update, @no_roles
    refute @senior_team_member_ability.can? :update, @no_roles
    refute @non_senior_team_member_ability.can? :update, @no_roles
    # TODO: This needs fixing - application_manager should not be able to change cas user info
    assert @application_manager_ability.can? :update, @no_roles
    refute @odr_ability.can? :update, @no_roles
    refute @senior_project_member_ability.can? :update, @no_roles
    refute @non_senior_project_member_ability.can? :update, @no_roles

    # should not be able to update other user's user details
    refute @no_roles_ability.can? :update, @senior_team_member
  end

  test 'dataset version abilities published scope' do
    dataset = Dataset.create!(name: 'Not Published Version', dataset_type: dataset_type(:table_spec),
                              team: Team.first)
    not_published = DatasetVersion.create!(semver_version: '1.0', dataset: dataset)
    assert @admin.can? :read, not_published
    assert @admin.can? :publish, not_published
    assert @senior_team_member_ability.cannot? :read, not_published
    assert @application_manager_ability.cannot? :read, not_published
    assert @non_senior_team_member_ability.cannot? :read, not_published

    published = not_published.tap { |dv| dv.update_attribute(:published, true) }
    assert @admin.can? :read, published
    assert @admin.cannot? :publish, published
    assert @senior_team_member_ability.can? :read, published
    assert @application_manager_ability.can? :read, published
    assert @non_senior_team_member_ability.can? :read, published
  end

  test 'cannot read dataset if no versions are published' do
    dataset = Dataset.create!(name: 'No Published Versions', dataset_type: dataset_type(:xml),
                              team: Team.first)
    [1, 2].each { |v| DatasetVersion.create!(semver_version: v, dataset: dataset) }
    assert @admin.can? :read, dataset
    assert @senior_team_member_ability.cannot? :read, dataset
    assert @application_manager_ability.cannot? :read, dataset
    assert @non_senior_team_member_ability.cannot? :read, dataset
  end

  test 'non table specification grants' do
    table_spec = create_dataset(name: 'Linked', dataset_type: dataset_type(:table_spec),
                                team: Team.first)
    add_version_to_dataset(table_spec, semver_version: '1', published: true)
    logical = create_dataset(name: 'XML', dataset_type: dataset_type(:xml), team: Team.first)
    no_grants_user = User.new(username: 'no_grant', first_name: 'Grant', last_name: 'Mitchell',
                              email: 'no_grants@phe.gov.uk')
    no_grants_user.save(validate: false)
    no_grants_user_ability = Ability.new(no_grants_user)

    assert no_grants_user_ability.can? :read, table_spec
    assert no_grants_user_ability.cannot? :read, logical

    add_version_to_dataset(logical, semver_version: '1', published: true)

    assert no_grants_user_ability.can? :read, logical
  end

  test 'data viewer grant' do
    table_spec = create_dataset(name: 'Linked', dataset_type: dataset_type(:table_spec),
                                team: Team.first)
    add_version_to_dataset(table_spec, semver_version: '1', published: true)
    logical = create_dataset(name: 'XML', dataset_type: dataset_type(:xml),
                             team: Team.first)
    add_version_to_dataset(logical, semver_version: '1', published: true)

    refute @senior_team_member_ability.can? :read, logical
    assert @senior_team_member_ability.can? :read, table_spec

    user_with_team_and_dataset_viewer_grant =
      User.new(username: 'tdv', first_name: 'Team', last_name: 'And Dataset Viewer User',
               email: 'no_grants@phe.gov.uk')
    user_with_team_and_dataset_viewer_grant.grants.build(
      roleable: TeamRole.fetch(:mbis_applicant), team: Team.first
    )
    user_with_team_and_dataset_viewer_grant.grants.build(
      roleable: SystemRole.fetch(:dataset_viewer)
    )
    user_with_team_and_dataset_viewer_grant.save(validate: false)
    user_with_team_and_dataset_viewer_grant_ability =
      Ability.new(user_with_team_and_dataset_viewer_grant)

    assert user_with_team_and_dataset_viewer_grant_ability.can? :read, logical
    assert user_with_team_and_dataset_viewer_grant_ability.can? :read, table_spec
  end

  test 'dataset manager grant' do
    table_spec = create_dataset(name: 'Linked', dataset_type: dataset_type(:table_spec),
                                team: Team.first)
    other_team_dataset = create_dataset(name: 'Other Team Dataset',
                                        dataset_type: dataset_type(:table_spec),
                                        team: Team.second)
    dataset_manager_ability = Ability.new(@dataset_manager)

    assert dataset_manager_ability.can? :create, Team.first.datasets.build
    # Should be able to see dataset that has no versions
    assert dataset_manager_ability.can? :read, table_spec
    # can't create a dataset for team who user doesn't belong to
    refute dataset_manager_ability.can? :create, Team.second.datasets.build
    # Can't see another team's dataset with no versions
    refute dataset_manager_ability.can? :read, other_team_dataset
    # can create a new dataset version for a team that user has role for
    assert dataset_manager_ability.can? :create, table_spec => DatasetVersion
    # cannot create a new dataset version for a team that user has no role for
    refute dataset_manager_ability.can? :create, other_team_dataset => DatasetVersion
  end

  test 'project end user grants' do
    user = User.new(username: 'end_user', email: 'end_user@phe.gov.uk')
    user.save(validate: false)
    project = Project.new(project_type: ProjectType.find_by(name: 'Application'), name: 'test')
    project.save(validate: false) && project.reload

    Grant.create!(user: user, roleable: TeamRole.fetch(:mbis_applicant))
    Grant.create!(user: user, roleable: ProjectRole.fetch(:owner), project: project)

    project.stubs(current_state: Workflow::State.find_by(id: 'CONTRACT_COMPLETED'))
    user_ability = Ability.new(user)
    assert user_ability.cannot? :create, project.project_data_end_users.build
    assert user_ability.cannot? :create, project.project_attachments.build

    project.stubs(current_state: Workflow::State.find_by(id: 'DRAFT'))

    assert user_ability.can? :create, project.project_data_end_users.build
    assert user_ability.can? :create, project.project_attachments.build

    project.project_type = ProjectType.find_by(name: 'Project')
    project.save(validate: false) && project.reload

    project.stubs(current_state: Workflow::State.find_by(id: 'APPROVED'))
    assert user_ability.can? :create, project.project_data_end_users.build
    assert user_ability.can? :create, project.project_attachments.build
  end

  test 'analyst can read era fields' do
    user = User.new(username: 'analyst', email: 'analyst@phe.gov.uk')
    user.save(validate: false);
    analyst_ability = Ability.new(user)
    refute analyst_ability.can? :read, EraFields

    grant = Grant.create!(user: user, roleable: SystemRole.fetch(:dataset_viewer_analyst))

    user.reload
    analyst_ability = Ability.new(user)
    assert analyst_ability.can? :read, EraFields

    grant.destroy!
    user.reload
    analyst_ability = Ability.new(user)
    refute analyst_ability.can? :read, EraFields
  end

  test 'project_amendment grants' do
    project_member      = users(:standard_user1)
    project_owner       = users(:standard_user2)
    other_user          = users(:standard_user)
    application_manager = users(:application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    project = build_project(team: teams(:team_one), project_type: project_types(:application))
    project.grants.build(user: project_member, roleable: ProjectRole.fetch(:read_only))
    project.save!

    project.project_states.create!(state: workflow_states(:amend))
    project.reload_current_state

    amendment = create_amendment(project)

    assert project_member.can?      :read, amendment
    assert project_owner.can?       :read, amendment
    assert application_manager.can? :read, amendment
    assert odr_user.can?            :read, amendment
    assert admin_user.can?          :read, amendment
    refute other_user.can?          :read, amendment

    refute project_member.can?      :create, amendment
    refute project_owner.can?       :create, amendment
    assert application_manager.can? :create, amendment
    refute odr_user.can?            :create, amendment
    refute admin_user.can?          :create, amendment
    refute other_user.can?          :create, amendment

    refute project_member.can?      :update, amendment
    refute project_owner.can?       :update, amendment
    assert application_manager.can? :update, amendment
    refute odr_user.can?            :update, amendment
    refute admin_user.can?          :update, amendment
    refute other_user.can?          :update, amendment

    refute project_member.can?      :destroy, amendment
    refute project_owner.can?       :destroy, amendment
    assert application_manager.can? :destroy, amendment
    refute odr_user.can?            :destroy, amendment
    refute admin_user.can?          :destroy, amendment
    refute other_user.can?          :destroy, amendment

    project.transition_to!(workflow_states(:dpia_start))

    refute application_manager.can? :create,  amendment
    refute application_manager.can? :update,  amendment
    refute application_manager.can? :destroy, amendment
  end

  test 'project_dpia grants' do
    project_member      = users(:standard_user1)
    project_owner       = users(:standard_user2)
    other_user          = users(:standard_user)
    application_manager = users(:application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    project = build_project(team: teams(:team_one), project_type: project_types(:application))
    project.grants.build(user: project_member, roleable: ProjectRole.fetch(:read_only))
    project.save!

    project.project_states.create!(state: workflow_states(:dpia_start))
    project.reload_current_state

    dpia = create_dpia(project)

    refute project_member.can?      :read, dpia
    refute project_owner.can?       :read, dpia
    assert application_manager.can? :read, dpia
    assert odr_user.can?            :read, dpia
    refute admin_user.can?          :read, dpia
    refute other_user.can?          :read, dpia

    refute project_member.can?      :create, dpia
    refute project_owner.can?       :create, dpia
    assert application_manager.can? :create, dpia
    refute odr_user.can?            :create, dpia
    refute admin_user.can?          :create, dpia
    refute other_user.can?          :create, dpia

    refute project_member.can?      :update, dpia
    refute project_owner.can?       :update, dpia
    assert application_manager.can? :update, dpia
    refute odr_user.can?            :update, dpia
    refute admin_user.can?          :update, dpia
    refute other_user.can?          :update, dpia

    refute project_member.can?      :destroy, dpia
    refute project_owner.can?       :destroy, dpia
    assert application_manager.can? :destroy, dpia
    refute odr_user.can?            :destroy, dpia
    refute admin_user.can?          :destroy, dpia
    refute other_user.can?          :destroy, dpia

    project.transition_to!(workflow_states(:dpia_review))

    refute application_manager.can? :create,  dpia
    refute application_manager.can? :update,  dpia
    refute application_manager.can? :destroy, dpia
  end

  test 'contract grants' do
    project_member      = users(:standard_user1)
    project_owner       = users(:standard_user2)
    other_user          = users(:standard_user)
    application_manager = users(:application_manager_one)
    senior_manager      = users(:senior_application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    project = build_project(team: teams(:team_one), project_type: project_types(:application))
    project.grants.build(user: project_member, roleable: ProjectRole.fetch(:read_only))
    project.save!

    project.project_states.create!(state: workflow_states(:contract_draft))
    project.reload_current_state

    contract = create_contract(project)

    refute project_member.can?      :read, contract
    refute project_owner.can?       :read, contract
    assert application_manager.can? :read, contract
    assert senior_manager.can?      :read, contract
    assert odr_user.can?            :read, contract
    refute admin_user.can?          :read, contract
    refute other_user.can?          :read, contract

    refute project_member.can?      :create, contract
    refute project_owner.can?       :create, contract
    assert application_manager.can? :create, contract
    assert senior_manager.can?      :create, contract
    assert odr_user.can?            :create, contract
    refute admin_user.can?          :create, contract
    refute other_user.can?          :create, contract

    refute project_member.can?      :update, contract
    refute project_owner.can?       :update, contract
    assert application_manager.can? :update, contract
    assert senior_manager.can?      :update, contract
    assert odr_user.can?            :update, contract
    refute admin_user.can?          :update, contract
    refute other_user.can?          :update, contract

    refute project_member.can?      :destroy, contract
    refute project_owner.can?       :destroy, contract
    assert application_manager.can? :destroy, contract
    assert senior_manager.can?      :destroy, contract
    assert odr_user.can?            :destroy, contract
    refute admin_user.can?          :destroy, contract
    refute other_user.can?          :destroy, contract
  end

  test 'release grants' do
    project_member      = users(:standard_user1)
    project_owner       = users(:standard_user2)
    other_user          = users(:standard_user)
    application_manager = users(:application_manager_one)
    senior_manager      = users(:senior_application_manager_one)
    odr_user            = users(:odr_user)
    admin_user          = users(:admin_user)

    project = build_project(team: teams(:team_one), project_type: project_types(:application))
    project.grants.build(user: project_member, roleable: ProjectRole.fetch(:read_only))
    project.save!

    release = project.releases.build

    refute project_member.can?      :read, release
    refute project_owner.can?       :read, release
    assert application_manager.can? :read, release
    assert senior_manager.can?      :read, release
    assert odr_user.can?            :read, release
    refute admin_user.can?          :read, release
    refute other_user.can?          :read, release

    refute project_member.can?      :create, release
    refute project_owner.can?       :create, release
    assert application_manager.can? :create, release
    assert senior_manager.can?      :create, release
    refute odr_user.can?            :create, release
    refute admin_user.can?          :create, release
    refute other_user.can?          :create, release

    refute project_member.can?      :update, release
    refute project_owner.can?       :update, release
    assert application_manager.can? :update, release
    assert senior_manager.can?      :update, release
    refute odr_user.can?            :update, release
    refute admin_user.can?          :update, release
    refute other_user.can?          :update, release

    refute project_member.can?      :destroy, release
    refute project_owner.can?       :destroy, release
    assert application_manager.can? :destroy, release
    assert senior_manager.can?      :destroy, release
    refute odr_user.can?            :destroy, release
    refute admin_user.can?          :destroy, release
    refute other_user.can?          :destroy, release
  end

  test 'update application as ODR application manager' do
    user = users(:application_manager_one)

    editable_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      assert user.can? :update, @project
    end

    no_edit_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      refute user.can? :update, @project
    end
  end

  test 'create project attachments when as application manager' do
    user = users(:application_manager_one)

    editable_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      assert user.can? :create, @project.project_attachments.build
    end

    no_edit_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      assert user.can? :create, @project.project_attachments.build
    end
  end

  test 'create project datasets when in DRAFT as application manager' do
    user = users(:application_manager_one)

    editable_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      assert user.can? :create, @project.project_datasets.build
    end

    no_edit_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      refute user.can? :create, @project.project_datasets.build
    end
  end

  test 'create project nodes when in DRAFT as application manager' do
    user = users(:application_manager_one)

    editable_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      assert user.can? :create, @project.project_nodes.build
    end

    no_edit_states.each do |state|
      @project.stubs current_state: workflow_states(state)
      refute user.can? :create, @project.project_nodes.build
    end
  end

  test 'comments' do
    user        = users(:standard_user1)
    commentable = projects(:dummy_project)

    comment_one = Comment.create!(
      commentable: commentable,
      user: user,
      body: 'I like to move it, move it'
    )

    comment_two = Comment.create!(
      commentable: commentable,
      user: users(:standard_user2),
      body: 'I love Zoflora'
    )

    assert user.can? :create, comment_one
    refute user.can? :delete, comment_one
    refute user.can? :create, comment_two
    refute user.can? :delete, comment_two
  end

  test 'can create CAS application with no roles' do
    mbis_application    = Project.new(project_type: ProjectType.find_by(name: 'Project'))
    odr_eoi_application = Project.new(project_type: ProjectType.find_by(name: 'EOI'))
    odr_application     = Project.new(project_type: ProjectType.find_by(name: 'Application'))
    cas_application     = Project.new(project_type: ProjectType.find_by(name: 'CAS'))
    assert @no_roles_ability.cannot? :create, mbis_application
    assert @no_roles_ability.cannot? :create, odr_eoi_application
    assert @no_roles_ability.cannot? :create, odr_application
    assert @no_roles_ability.can?    :create, cas_application
  end

  test 'a user with roles can create CAS application' do
    cas_application = Project.new(project_type: ProjectType.find_by(name: 'CAS'))
    assert @application_manager_ability.can?    :create, cas_application
  end

  test 'jobs' do
    user                = users(:standard_user)
    application_manager = users(:application_manager_one)
    odr                 = users(:odr_user)
    administrator       = users(:admin_user)
    developer           = users(:developer)

    refute user.can?                :read, Delayed::Job
    refute application_manager.can? :read, Delayed::Job
    refute odr.can?                 :read, Delayed::Job
    refute administrator.can?       :read, Delayed::Job
    assert developer.can?           :read, Delayed::Job

    refute user.can?                :delete, Delayed::Job
    refute application_manager.can? :delete, Delayed::Job
    refute odr.can?                 :delete, Delayed::Job
    refute administrator.can?       :delete, Delayed::Job
    assert developer.can?           :delete, Delayed::Job
  end

  test 'communications' do
    user                = users(:standard_user)
    application_manager = users(:application_manager_one)
    odr                 = users(:odr_user)
    administrator       = users(:admin_user)
    developer           = users(:developer)

    refute user.can?                :read, Communication
    assert application_manager.can? :read, Communication
    refute odr.can?                 :read, Communication
    refute administrator.can?       :read, Communication
    refute developer.can?           :read, Communication

    refute user.can?                :create, Communication
    assert application_manager.can? :create, Communication
    refute odr.can?                 :create, Communication
    refute administrator.can?       :create, Communication
    refute developer.can?           :create, Communication

    refute user.can?                :delete, Communication
    assert application_manager.can? :delete, Communication
    refute odr.can?                 :delete, Communication
    refute administrator.can?       :delete, Communication
    refute developer.can?           :delete, Communication
  end

  private

  def create_dataset(options)
    Dataset.create!(options)
  end

  def add_version_to_dataset(dataset, options)
    dataset.dataset_versions.build(options)
    dataset.save!
  end

  def dataset_manager_setup
    @dataset_manager = User.new(username: 'dm', first_name: 'Dataset',
                                last_name: 'Manager', email: 'dm@phe.gov.uk')
    @dataset_manager.grants.build(roleable: TeamRole.fetch(:dataset_manager), team: Team.first)
    @dataset_manager.save(validate: false)
  end

  def no_edit_states
    %i[submitted dpia_start dpia_review dpia_moderation dpia_rejected
       contract_draft contract_rejected contract_completed]
  end

  def editable_states
    %i[draft amend]
  end
end
