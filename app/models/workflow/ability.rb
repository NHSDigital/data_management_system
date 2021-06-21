module Workflow
  # Defines high level grants relating to workflows.
  class Ability
    include CanCan::Ability

    def initialize(user)
      @user = user

      as_basic_user
      as_project_member
      as_project_senior
      as_team_delegate
      as_odr_user
      as_administrator

      merge(ProjectWorkflowAbility.new(user))
      merge(EoiWorkflowAbility.new(user))
      merge(ApplicationWorkflowAbility.new(user))
      merge(CasWorkflowAbility.new(user))
    end

    private

    def as_basic_user; end

    def as_project_member
      role = ProjectRole.can_edit
      project_ids = @user.projects.active.through_grant_of(role).pluck('grants.project_id')

      can :read, ProjectState, project_id: project_ids

      can :create, Assignment, project: {
        current_project_state: {
          assigned_user_id: @user.id
        }
      }
    end

    # TODO: disable a project contributor from transitioning
    def as_project_senior
      role  = TeamRole.applicants
      teams = @user.teams.through_grant_of(role)
      project_conditions = { team: teams }

      can :read,       ProjectState, project: project_conditions
      can :transition, Project,      project_conditions
    end

    def accessible_projects_via(role, user)
      user.projects.active.through_grant_of(role)
    end

    def as_team_delegate
      role  = TeamRole.delegates
      teams = @user.teams.through_grant_of(role)
      project_conditions = { team: teams }

      can :read,       ProjectState, project: project_conditions
      can :transition, Project,      project_conditions
    end

    def as_odr_user
      return unless @user.application_manager? || @user.senior_application_manager? || @user.odr?

      can :read,       ProjectState
      can :transition, Project
      can :create,     Assignment
    end

    def as_administrator; end
  end

  # Defines authorization rules relating to the project workflow.
  class ProjectWorkflowAbility
    include CanCan::Ability

    def initialize(user)
      @user = user

      as_basic_user
      as_project_member
      as_project_senior
      as_team_delegate
      as_odr_user
      as_administrator
    end

    private

    def as_basic_user; end

    def as_project_member; end

    def as_project_senior
      project_conditions = {
        project_type: { name: 'Project' },
        grants: { user_id: @user.id, roleable: ProjectRole.fetch(:owner) }
      }

      can :create,    ProjectState, state: { id: 'DRAFT' },
                                    project: project_conditions.merge(
                                      current_state: { id: %w[REVIEW SUBMITTED REJECTED] }
                                    )

      can :create,    ProjectState, state: { id: 'REVIEW' },
                                    project: project_conditions.merge(
                                      current_state: { id: 'DRAFT' }
                                    )

      can :create,    ProjectState, state: { id: 'DELETED' },
                                    project: project_conditions
    end

    def as_team_delegate
      project_conditions = {
        project_type: { name: 'Project' },
        team: { grants: { user_id: @user.id, roleable: TeamRole.delegates } }
      }

      can :create, ProjectState, state: { id: %w[SUBMITTED REJECTED] },
                                 project: project_conditions.merge(
                                   current_state: { id: 'REVIEW' }
                                 )
    end

    def as_odr_user
      return unless @user.odr?

      project_conditions = { project_type: { name: 'Project' } }

      # Technically possible by pre-existing code behaviour, but undesirable?
      # can :create, ProjectState, state: { id: 'SUBMITTED' },
      #                            project: project_conditions.merge(
      #                              current_state: { id: %w[APPROVED REJECTED] }
      #                            )

      can :create, ProjectState, state: { id: %w[APPROVED REJECTED] },
                                 project: project_conditions.merge(
                                   current_state: { id: 'SUBMITTED' }
                                 )
    end

    def as_administrator
      return unless @user.administrator?

      can :read, ProjectState
    end
  end

  # Defines authorization rules relating to the project workflow.
  class EoiWorkflowAbility
    include CanCan::Ability

    def initialize(user)
      @user = user

      as_basic_user
      as_project_member
      as_project_senior
      as_team_delegate
      as_odr_user
      as_application_manager
      as_administrator
    end

    private

    def as_basic_user; end

    def as_project_member; end

    def as_project_senior
      project_conditions = { project_type: { name: 'EOI' },
                             grants: { user_id: @user.id, roleable: ProjectRole.fetch(:owner) } }

      can :create, ProjectState, state: { id: 'DRAFT' },
                                 project: project_conditions.merge(
                                   current_state: { id: 'SUBMITTED' }
                                 )

      can :create, ProjectState, state: { id: 'SUBMITTED' },
                                 project: project_conditions.merge(
                                   current_state: { id: 'DRAFT' }
                                 )

      can :create, ProjectState, state: { id: 'DELETED' },
                                 project: project_conditions.merge(
                                   current_state: { id: %w[DRAFT APPROVED REJECTED] }
                                 )
    end

    def as_team_delegate; end

    def as_odr_user
      return unless @user.application_manager? || @user.senior_application_manager? || @user.odr?

      can :create, ProjectState, state: { id: %w[APPROVED REJECTED] },
                                 project: {
                                   project_type: { name: 'EOI' },
                                   assigned_user_id: @user.id,
                                   current_state: { id: 'SUBMITTED' }
                                 }
    end

    # TODO: there may be more needed for this and Application ProjectType
    def as_application_manager
      return unless @user.application_manager?

      can :create, ProjectState, state: { id: 'DRAFT' },
                                 project: {
                                   project_type: { name: 'EOI' },
                                   current_state: { id: 'SUBMITTED' }
                                 }

      can :create, ProjectState, state: { id: 'SUBMITTED' },
                                 project: {
                                   project_type: { name: 'EOI' },
                                   current_state: { id: %w[DRAFT SUBMITTED] }
                                 }

      can :create, ProjectState, state: { id: 'DELETED' },
                                 project: {
                                   project_type: { name: 'EOI' },
                                   current_state: { id: 'SUBMITTED' }
                                 }

      can :create, ProjectState, state: { id: 'DELETED' },
                                 project: {
                                   project_type: { name: 'EOI' },
                                   current_state: { id: %w[DRAFT APPROVED REJECTED] }
                                 }
    end

    def as_administrator; end
  end

  # Defines authorization rules relating to the Application workflow.
  class ApplicationWorkflowAbility
    include CanCan::Ability

    def initialize(user)
      @user = user

      as_basic_user
      as_project_member
      as_project_senior
      as_team_delegate
      as_odr_user
      as_administrator
    end

    private

    def as_basic_user; end

    def as_project_member; end

    def as_project_senior
      can :create, ProjectState, state: { id: %w[SUBMITTED] },
                                 project: {
                                   project_type: { name: 'Application' },
                                   current_state: { id: %w[DRAFT] },
                                   grants: { user_id: @user.id, roleable: ProjectRole.fetch(:owner) }
                                 }

      can :create, ProjectState, state: { id: %w[DRAFT] },
                                project: {
                                  project_type: { name: 'Application' },
                                  current_state: { id: %w[SUBMITTED] },
                                  grants: { user_id: @user.id, roleable: ProjectRole.fetch(:owner) }
                                }
    end

    def as_team_delegate; end

    def as_odr_user
      if @user.application_manager?
        can :create, ProjectState, state: { id: %w[SUBMITTED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: %w[DRAFT] }
                                   }

        can :create, ProjectState, state: { id: %w[DRAFT] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: %w[SUBMITTED] }
                                   }

        can :create, ProjectState, state: { id: %w[DPIA_START] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     assigned_user_id: @user.id,
                                     current_state: {
                                       id: %w[
                                         SUBMITTED
                                         DPIA_REJECTED
                                         CONTRACT_REJECTED
                                         AMEND
                                       ]
                                     }
                                   }

        can :create, ProjectState, state: { id: %w[DPIA_REVIEW] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     assigned_user_id: @user.id,
                                     current_state: { id: 'DPIA_START' }
                                   }

        can :create, ProjectState, state: { id: %w[DPIA_REJECTED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_project_state: {
                                       state_id: 'DPIA_REVIEW',
                                       assigned_user_id: @user.id
                                     }
                                   }

        can :create, ProjectState, state: { id: %w[DPIA_MODERATION] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_project_state: {
                                       state_id: 'DPIA_REVIEW',
                                       assigned_user_id: @user.id
                                     }
                                   }

        can :create, ProjectState, state: { id: 'AMEND' },
                                   project: {
                                      project_type: { name: 'Application' },
                                      assigned_user_id: @user.id,
                                      current_state: {
                                        id: %w[
                                          DPIA_START
                                          DPIA_REVIEW
                                          DPIA_MODERATION
                                          DPIA_REJECTED
                                          CONTRACT_DRAFT
                                          CONTRACT_REJECTED
                                          CONTRACT_COMPLETED
                                        ]
                                      }
                                   }
        can :create, ProjectState, state: { id: 'REJECTED' },
                                   project: {
                                      project_type: { name: 'Application' },
                                      assigned_user_id: @user.id,
                                      current_state: {
                                        id: %w[
                                          DPIA_START
                                          DPIA_REVIEW
                                          DPIA_MODERATION
                                          DPIA_REJECTED
                                          CONTRACT_REJECTED
                                          CONTRACT_COMPLETED
                                          CONTRACT_DRAFT
                                          SUBMITTED
                                          AMEND
                                          DRAFT
                                          DATA_RELEASED
                                          DATA_DESTROYED
                                        ]
                                      }
                                   }
        # plan.io 23971
        can :create, ProjectState, state: { id: %w[DATA_RELEASED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: 'CONTRACT_COMPLETED' }
                                   }
        can :create, ProjectState, state: { id: %w[DATA_DESTROYED AMEND] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: 'DATA_RELEASED' }
                                   }

        # can reopen to last previous state. permissions for that state should then be restoed
        # e.g application can reopen to contract_draft but then won't be able to action it
        can :create, ProjectState, state: { id: %w[
                                                  DPIA_START
                                                  DPIA_REVIEW
                                                  DPIA_MODERATION
                                                  DPIA_REJECTED
                                                  CONTRACT_REJECTED
                                                  CONTRACT_COMPLETED
                                                  CONTRACT_DRAFT
                                                  SUBMITTED
                                                  AMEND
                                                  DRAFT
                                                  DATA_RELEASED
                                                  DATA_DESTROYED
                                                ] },
                                   project: {
                                      project_type: { name: 'Application' },
                                      current_state: {
                                        id: %w[REJECTED]
                                      }
                                   }
      end

      if @user.senior_application_manager?
        can :create, ProjectState, state: { id: %w[DPIA_REJECTED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_project_state: {
                                       state_id: 'DPIA_MODERATION',
                                       assigned_user_id: @user.id
                                     }
                                   }

        can :create, ProjectState, state: { id: %w[CONTRACT_DRAFT] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_project_state: {
                                       state_id: 'DPIA_MODERATION',
                                       assigned_user_id: @user.id
                                     }
                                   }
        can :create, ProjectState, state: { id: %w[
                                                  DPIA_START
                                                  DPIA_REVIEW
                                                  DPIA_MODERATION
                                                  DPIA_REJECTED
                                                  CONTRACT_REJECTED
                                                  CONTRACT_COMPLETED
                                                  CONTRACT_DRAFT
                                                  SUBMITTED
                                                  AMEND
                                                  DRAFT
                                                  DATA_RELEASED
                                                  DATA_DESTROYED
                                                ] },
                                   project: {
                                      project_type: { name: 'Application' },
                                      current_state: {
                                        id: %w[REJECTED]
                                      }
                                   }
      end

      if @user.odr?
        can :create, ProjectState, state: { id: %w[CONTRACT_REJECTED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: 'CONTRACT_DRAFT' }
                                   }

        can :create, ProjectState, state: { id: %w[CONTRACT_COMPLETED] },
                                   project: {
                                     project_type: { name: 'Application' },
                                     current_state: { id: 'CONTRACT_DRAFT' }
                                   }
      end
    end

    def as_administrator; end
  end

  # Temporary patch to support the move to temporal assignment, where live systems may still
  # be using the project's assigned user (which should be the manager for the lifecycle of
  # the project) for reassignment along the workflow.
  # FIXME: Remove this once temporal assignment has bedded in across live systems.
  ApplicationWorkflowAbility.prepend(
    Module.new do
      def as_odr_user
        super

        if @user.application_manager?
          can :create, ProjectState, {
            state: {
              id: %w[DPIA_REJECTED]
            },
            project: {
              project_type: {
                name: 'Application'
              },
              current_project_state: {
                state_id: 'DPIA_REVIEW',
                assigned_user_id: nil
              },
              assigned_user_id: @user.id
            }
          }

          can :create, ProjectState, {
            state: {
              id: %w[DPIA_MODERATION]
            },
            project: {
              project_type: {
                name: 'Application'
              },
              current_project_state: {
                state_id: 'DPIA_REVIEW',
                assigned_user_id: nil
              },
              assigned_user_id: @user.id
            }
          }
        end

        if @user.senior_application_manager?
          can :create, ProjectState, {
            state: {
              id: %w[DPIA_REJECTED]
            },
            project: {
              project_type: {
                name: 'Application'
              },
              current_project_state: {
                state_id: 'DPIA_MODERATION',
                assigned_user_id: nil
              },
              assigned_user_id: @user.id
            }
          }

          can :create, ProjectState, {
            state: {
              id: %w[CONTRACT_DRAFT]
            },
            project: {
              project_type: {
                name: 'Application'
              },
              current_project_state: {
                state_id: 'DPIA_MODERATION',
                assigned_user_id: nil
              },
              assigned_user_id: @user.id
            }
          }
        end
      end
    end
  )

  # Defines authorization rules relating to the project workflow.
  class CasWorkflowAbility
    include CanCan::Ability

    def initialize(user)
      @user = user

      as_basic_user
      as_account_approver
      as_cas_manager
      # as_administrator
    end

    private

    def as_basic_user
      # Added to stop cas_manager inheriting roles as 'basic_user'
      return if @user.cas_manager?

      role = ProjectRole.fetch(:owner)
      project_ids = @user.projects.active.through_grant_of(role).pluck('grants.project_id')

      can :read, ProjectState, project_id: project_ids
      can :create, ProjectState, state: { id: 'DRAFT' },
                                 project: { current_state: { id: 'SUBMITTED' },
                                            project_type: { name: 'CAS' },
                                            id: project_ids }
      can :create, ProjectState, state: { id: 'SUBMITTED' },
                                 project: { current_state: { id: 'DRAFT' },
                                            project_type: { name: 'CAS' },
                                            id: project_ids }
      can :create, ProjectState, state: { id: 'ACCESS_GRANTED' },
                                 project: { current_state: { id: 'RENEWAL' },
                                            project_type: { name: 'CAS' },
                                            id: project_ids }
      can :create, ProjectState, state: { id: %w[ACCOUNT_CLOSED DRAFT] },
                                 project: { current_state: { id: 'ACCESS_GRANTED' },
                                            project_type: { name: 'CAS' },
                                            id: project_ids }
      can :create, ProjectState, state: { id: 'DRAFT' },
                                 project: { current_state: { id: 'REJECTION_REVIEWED' },
                                            project_type: { name: 'CAS' },
                                            id: project_ids }
      can :transition, Project, id: project_ids, project_type: { name: 'CAS' }
    end

    def as_account_approver
      return unless @user.cas_access_approver?

      role = ProjectRole.fetch(:owner)
      project_ids = @user.projects.active.through_grant_of(role).pluck('grants.project_id')

      can :create, ProjectState, state: { id: %w[ACCESS_APPROVER_APPROVED
                                                 ACCESS_APPROVER_REJECTED] },
                                 project: { current_state: { id: 'SUBMITTED' },
                                            project_type: { name: 'CAS' } }
      cannot :create, ProjectState, state: { id: %w[ACCESS_APPROVER_APPROVED
                                                    ACCESS_APPROVER_REJECTED] },
                                    project: { current_state: { id: 'SUBMITTED' },
                                               project_type: { name: 'CAS' },
                                               id: project_ids }
      can :transition, Project, project_type: { name: 'CAS' }
    end

    # Ticket suggests they shouldn't have any additional transition abilities over basic_user
    def as_cas_manager
      return unless @user.cas_manager?

      can :create, ProjectState, state: { id: 'SUBMITTED' },
                                 project: { current_state: { id: 'ACCESS_APPROVER_REJECTED' },
                                            project_type: { name: 'CAS' } }
      can :create, ProjectState, state: { id: 'REJECTION_REVIEWED' },
                                 project: { current_state: { id: 'ACCESS_APPROVER_REJECTED' },
                                            project_type: { name: 'CAS' } }
      can :create, ProjectState, state: { id: 'DRAFT' },
                                 project: { current_state: { id: 'ACCOUNT_CLOSED' },
                                            project_type: { name: 'CAS' } }
      can :create, ProjectState, state: { id: 'ACCOUNT_CLOSED' },
                                 project: { current_state: { id: 'ACCESS_GRANTED' },
                                            project_type: { name: 'CAS' } }
      can :transition, Project, project_type: { name: 'CAS' }
    end

    def as_administrator
      return unless @user.administrator?

      can :read, ProjectState
    end
  end
end
