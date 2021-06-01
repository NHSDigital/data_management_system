# This class defines the abilities a user has
class Ability
  include CanCan::Ability

  # TODO: Group rules by "roles".
  def initialize(user)
    alias_action :delete,     to: :destroy
    alias_action :update_all, to: :update
    alias_action :create, :read, :update, :destroy, to: :crud

    # NOTE: If `user` can :read the parent resource then it is assumed that they should be able to
    # :read any/all `comment`s on that resource (hence no :read permission defined for `Comment`).
    can %i[create], Comment, user_id: user.id

    can %i[terms_and_conditions read destroy], Notification
    can :destroy, UserNotification, user_id: user.id
    can %i[read update], User, id: user.id
    can :read, Grant, user_id: user.id
    can :read, [Category, Node]
    can :create, Project, project_type_id: ProjectType.cas.pluck(:id)
    can :read, Project, project_type_id: ProjectType.cas.pluck(:id),
                        grants: { user_id: user.id, roleable: ProjectRole.owner }
    # TODO: do we still want them to be able to destroy?
    can %i[update destroy], Project, project_type_id: ProjectType.cas.pluck(:id),
                                     grants: { user_id: user.id, roleable: ProjectRole.owner },
                                     current_state: { id: 'DRAFT' }
    can %i[reapply], ProjectDataset, approved: false,
                                     project: { project_type_id: ProjectType.cas.pluck(:id),
                                                current_state: {
                                                  id: Workflow::State.reapply_dataset_states.pluck(:id)
                                                },
                                                grants: { user_id: user.id,
                                                          roleable: ProjectRole.owner } }
    team_grants(user)
    organisation_grants(user)

    project_grants(user)
    project_data_source_item_grants(user)
    project_data_end_user_grants(user)
    project_attachment_grants(user)

    odr_grants(user)
    delegator_grants(user)
    administrator_grants(user)
    application_manager_grants(user)
    dataset_manager_grants(user)
    non_dms_user(user)
    table_spec_dataset_grants(user)
    dataset_viewer_grants(user)
    dataset_viewer_analyst_grants(user)

    cas_dataset_approver_grants(user)
    cas_access_approver_grants(user)
    cas_manager_grants(user)

    developer_grants(user)
    merge(Workflow::Ability.new(user))
  end

  def team_grants(user)
    can %i[teams projects], User
    roles = TeamRole.applicants + TeamRole.read_only
    roles << TeamRole.fetch(:dataset_manager)
    can :read, Team, grants: { user_id: user.id, roleable: roles }
    cannot :edit_team_grants, User
    cannot :edit_project_grants, User
  end

  def organisation_grants(user)
    can :read, Organisation, teams: { grants: { user_id: user.id } }
  end

  def project_grants(user)
    # Can create projects for their team
    can %i[create], Project,
        team: { grants: { user_id: user.id, roleable: TeamRole.applicants } }

    # Can only read projects that have a read only grant on
    role = ProjectRole.read_only
    read_only_project_ids = accessible_projects_via(role, user).pluck('grants.project_id')

    can %i[read show_ons_access_agreement show_ons_declaration_use show_ons_declaration_list],
        Project, grants: { user_id: user.id, project_id: read_only_project_ids,
                           roleable: ProjectRole.read_only }

    role = ProjectRole.can_edit
    can_edit_project_ids = accessible_projects_via(role, user).pluck('grants.project_id')

    can %i[read show duplicate], Project, grants: { user_id: user.id,
                                                    project_id: can_edit_project_ids,
                                                    roleable: ProjectRole.can_edit }

    can %i[update destroy edit_ons_data_access
           edit_ons_declaration edit_data_source_items],
        Project, grants: { user_id: user.id, project_id: can_edit_project_ids,
                           roleable: ProjectRole.can_edit },
                 current_state: { id: 'DRAFT' }

    can %i[read], [ProjectDataset, ProjectNode,
                   ProjectEndUse, ProjectClassification, ProjectLawfulBasis],
        project: { grants: { user_id: user.id, project_id: can_edit_project_ids,
                             roleable: ProjectRole.can_edit } }

    can %i[edit_ons_data_access edit_ons_declaration edit_data_source_items],
        Project, senior_user_id: user.id

    # QUESTION: Are these actually sub-resources?
    # can %i[show_ons_access_agreement show_ons_declaration_use show_ons_declaration_list],
    #     Project, project_memberships: { membership: { user_id: user.id } }
    # can %i[edit_ons_data_access edit_ons_declaration edit_data_source_items],
    #     Project, senior_user_id: user.id

    role = ProjectRole.owner
    project_ids = accessible_projects_via(role, user).pluck('grants.project_id')

    can %i[edit_grants reset_password], User,
        grants: { project_id: project_ids, roleable: ProjectRole.owner }

    # Can add read only grants to for users to a  project the user owns
    owned_project_ids = Project.owned_by(user).pluck(:project_id)
    can %i[read toggle destroy], Grant,
        project: { grants: { user_id: user.id, roleable: ProjectRole.owner,
                             project_id: owned_project_ids } }

    can :read, ProjectAmendment, project: { grants: { user_id: user.id } }
  end

  # For the user, returns the active projects they're able to access
  # from being granted `role`
  def accessible_projects_via(role, user)
    user.projects.active.through_grant_of(role)
  end

  def project_attachment_grants(user)
    can %i[create read destroy], ProjectAttachment, project: {
      grants: { user_id: user.id, project_id: project_ids_for(user),
                roleable: ProjectRole.can_edit },
      current_state: { id: 'DRAFT' },
      project_type_id: ProjectType.where(name: %w[EOI Application]).pluck(:id)
    }

    can %i[create read destroy], ProjectAttachment, project: {
      grants: { user_id: user.id, project_id: project_ids_for(user),
                roleable: ProjectRole.can_edit },
      current_state: { id: Workflow::State.not_submitted_for_sign_off.map(&:id) },
      project_type_id: ProjectType.find_by(name: 'Project').id
    }
  end

  def project_data_source_item_grants(user)
    can %i[create destroy], ProjectNode, project: {
      grants: { user_id: user.id, project_id: project_ids_for(user),
                roleable: ProjectRole.can_edit },
      current_state: { id: 'DRAFT' }
    }
  end

  def project_data_end_user_grants(user)
    can %i[create destroy], ProjectDataEndUser, project: {
      grants: { user_id: user.id, project_id: project_ids_for(user),
                roleable: ProjectRole.can_edit },
      current_state: { id: 'DRAFT' },
      project_type_id: ProjectType.where(name: %w[EOI Application]).pluck(:id)
    }

    can %i[create destroy], ProjectDataEndUser, project: {
      grants: { user_id: user.id, project_id: project_ids_for(user),
                roleable: ProjectRole.can_edit },
      current_state: { id: Workflow::State.not_submitted_for_sign_off.map(&:id) },
      project_type_id: ProjectType.find_by(name: 'Project').id
    }
  end

  def administrator_grants(user)
    return unless user.administrator?

    # TODO: Avoid block conditions where possible.
    can %i[read create update], Team
    can(:destroy, Team) { |team| team.z_team_status.name != 'Deleted' }

    can :read, [Project, ProjectDataset, ProjectNode, ProjectAmendment,
                ProjectEndUse, ProjectClassification, ProjectLawfulBasis]

    # Manage allows :edit_grants
    can :manage, [User, Dataset, Category, Node, EraFields,
                  Organisation, Division, Directorate, NodeCategory]

    # can :manage, DatasetVersion
    can :manage, DatasetVersion, published: false
    can :read, DatasetVersion, published: true

    can %i[read toggle destroy], Grant
  end

  # TODO: Can we merge :odr_grants and :application_manager_grants ?
  def odr_grants(user)
    return unless user.odr? || user.role?(SystemRole.fetch(:application_manager))

    can :read, [
      Organisation, Team, User, Project, ProjectAttachment, ProjectDataset,
      ProjectNode, ProjectAmendment, DataPrivacyImpactAssessment, Contract, Release, ProjectEndUse,
      ProjectClassification, ProjectLawfulBasis
    ]

    can %i[assign import], Project

    # Senior ODR users have additonal powers...
    return unless user.odr?

    can :read, Project, project_type_id: ProjectType.odr_mbis.pluck(:id)

    can %i[create update], Contract

    can %i[destroy], Contract, project: {
      current_state: { id: %w[CONTRACT_DRAFT CONTRACT_COMPLETED] }
    }

    # QUESTION: Are we actually looking at Approval resources on a polymorphic Approvable object?
    can %i[approve_members approve_details approve_legal], Project

    can :reset_project_approvals, Project, current_state: { id: 'SUBMITTED' }
    can :approve, Project, current_state: { id: 'SUBMITTED' }

    # TODO: Deprecated. Remove once workflows fully plumbed in.
    can %i[odr_submit_project_approvals], Project

    # TODO: this needs to chage to approve as normal users / admin can update
    can :approve, ProjectNode
  end

  def delegator_grants(user)
    return unless user.role?(TeamRole.fetch(:mbis_delegate))

    can :read, Team, grants: { user_id: user.id }
    can %i[read], Project, team: { grants: { user_id: user.id } }
    can :read, [ProjectDataset, ProjectNode, ProjectEndUse, ProjectClassification,
                ProjectLawfulBasis],
               project: { team: { grants: { user_id: user.id } } }
  end

  # TODO: Do we need a project_user_type model that determines what project_types a user can see
  # TODO Should we have a generic application_approver role that applies across all project_types
  # CAS - Cas_Access_Approver, MBIS - Delegate, ODR - Application_Manager, CARA - ?
  def application_manager_grants(user)
    junior = user.role?(SystemRole.fetch(:application_manager))
    senior = user.role?(SystemRole.fetch(:senior_application_manager))
    return unless junior || senior

    can :manage, [User, Organisation, Division, Directorate, Team]

    can :create, Project
    can :read, Project, project_type_id: ProjectType.odr_mbis.pluck(:id)
    can %i[create read], ProjectAttachment
    can %i[update destroy edit_data_source_items],
        Project, current_state: { id: %w[DRAFT AMEND] }
    [ProjectDataset, ProjectNode].each { |klass| application_manager_edit_ability(klass) }

    cannot :edit_system_grants, User
    can %i[read toggle destroy], Grant
    can :read, Dataset, dataset_versions: { published: true }
    can :read, DatasetVersion, published: true

    can :read, ProjectAmendment
    can %i[create update destroy], ProjectAmendment, project: { current_state: { id: 'AMEND' } }

    can :read, DataPrivacyImpactAssessment
    can %i[create update destroy], DataPrivacyImpactAssessment, project: {
      current_state: { id: 'DPIA_START' }
    }

    can %i[read create update], Contract

    can %i[destroy], Contract, project: {
      current_state: { id: %w[CONTRACT_DRAFT CONTRACT_COMPLETED] }
    }

    can %i[create read update destroy], Release

    can %i[create read destroy], Communication

    can :read, [ProjectEndUse, ProjectClassification, ProjectLawfulBasis]
  end

  def dataset_manager_grants(user)
    return unless user.role?(TeamRole.fetch(:dataset_manager))

    conditions = { dataset: { team: { grants: { user_id: user.id } } } }
    can %i[publish], DatasetVersion, conditions
    can %i[download], DatasetVersion

    # 1) Can Create and manage a dataset for a team user has role for.
    crud_conditions =
      { team: { grants: { user_id: user.id, roleable_id: TeamRole.fetch(:dataset_manager).id } } }
    can :crud, Dataset, crud_conditions

    # 2) Can read create show dataset versions for a team regardless of published state
    dataset_version_crs_conditions =
      { dataset: { team: { grants: { user_id: user.id,
                                     roleable_id: TeamRole.fetch(:dataset_manager).id } } } }
    can %i[read create show], DatasetVersion, dataset_version_crs_conditions

    # 3) Can only edit unpublished versions
    can %i[update destroy], DatasetVersion, dataset_version_crs_conditions.merge(published: false)

    # 4) Can see datasets of any type with at least one published version
    can :read, Dataset, dataset_versions: { published: true }

    # 5) Can see dataset_versions that are published regardless of team and dataset_type
    can :read, DatasetVersion, published: true
  end

  # i.e someone just browsing the system should be able to browse datasets
  def non_dms_user(user)
    return unless user.grants.count.zero?

    can :read, Dataset, logical_conditions
    can %i[read download], DatasetVersion, logical_version_conditions
  end

  # i.e a DMS user, someone making applications, should be able to browse table specifications
  # they could potentially request
  def table_spec_dataset_grants(user)
    return if user.grants.count.zero?

    dataset_conditions = { dataset_type: { name: 'table_specification' },
                           dataset_versions: { published: true } }
    can :read, Dataset, dataset_conditions
    dataset_version_conditions = { published: true,
                                   dataset: { dataset_type: { name: 'table_specification' } } }
    can %i[read download], DatasetVersion, dataset_version_conditions
  end

  def dataset_viewer_grants(user)
    return unless user.role?(SystemRole.fetch(:dataset_viewer))

    can :read, Dataset, logical_conditions
    can %i[read download], DatasetVersion, logical_version_conditions
  end

  def dataset_viewer_analyst_grants(user)
    return unless user.role?(SystemRole.fetch(:dataset_viewer_analyst))

    can :read, EraFields
  end

  def cas_dataset_approver_grants(user)
    return unless user.role?(DatasetRole.fetch(:approver))

    can %i[read], Project, project_type_id: ProjectType.cas.pluck(:id),
                           id: Project.cas_dataset_approval(user).map(&:id)
    can %i[update approve], ProjectDataset, dataset_id: user.datasets.pluck(:id),
                                            project: {
                                              id: Project.cas_dataset_approval(user).map(&:id)
                                            }
  end

  def cas_access_approver_grants(user)
    return unless user.role?(SystemRole.fetch(:cas_access_approver))

    can %i[read], Project, project_type_id: ProjectType.cas.pluck(:id),
                           current_state: { id: Workflow::State.access_approval_states.map(&:id) }
  end

  def cas_manager_grants(user)
    return unless user.role?(SystemRole.fetch(:cas_manager))

    can %i[read], Project, project_type_id: ProjectType.cas.pluck(:id)
  end

  def developer_grants(user)
    return unless user.role?(SystemRole.fetch(:developer))

    can %i[read destroy], Delayed::Job
  end

  private

  # where the user is an owner of active projects
  def senior_member_projects(user)
    user.projects.active.owned_by(user).pluck(:id)
  end

  def project_ids_for(user)
    roles = ProjectRole.can_edit
    accessible_projects_via(roles, user).pluck('grants.project_id')
  end

  # Can read dataset if at least one of it's versions is published
  def logical_conditions
    {
      dataset_type: { name: %w[xml non_xml table_specification] },
      dataset_versions: { published: true }
    }
  end

  def logical_version_conditions
    { published: true,
      dataset: { dataset_type: { name: %w[xml non_xml table_specification] } } }
  end

  def application_manager_edit_ability(klass)
    can %i[create update destroy], klass, project: { current_state: { id: %w[DRAFT AMEND] } }
  end
end
