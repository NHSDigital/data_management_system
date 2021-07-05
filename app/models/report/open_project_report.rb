module Report
  # ODR Report showing all open projects, to support offline working.
  # See Plan.IO #26902
  class OpenProjectReport < Base
    EXCLUDED_STATES = %w[
      DRAFT
      APPROVED
      REJECTED
      CLOSED
      DATA_DESTROYED
      DATA_RELEASED
      DELETED
    ].freeze

    self.columns = [
      {
        label:    Project.human_attribute_name(:application_log),
        accessor: :application_log
      },

      {
        label:    ProjectType.model_name.human,
        accessor: :project_type_translated_name
      },

      {
        label:    Project.human_attribute_name(:assigned_user),
        accessor: :application_manager
      },

      {
        label:    Project.human_attribute_name(:application_date),
        accessor: :application_date,
        format:   :strftime
      },

      {
        label:    ProjectAmendment.human_attribute_name(:reference),
        accessor: :amendment_reference
      },

      {
        label:    ProjectAmendment.human_attribute_name(:requested_at),
        accessor: :amendment_requested_at,
        format:   :strftime
      },

      {
        label:    ProjectAmendment.human_attribute_name(:amendment_approved_date),
        accessor: :amendment_approved_date,
        format:   :strftime
      },

      {
        label:    Release.human_attribute_name(:release_date),
        accessor: :data_release_date,
        format:   :strftime
      },

      {
        label:    Release.human_attribute_name(:individual_to_release),
        accessor: :individual_to_release
      },

      {
        label:    Workflow::Assignment.human_attribute_name(:assigned_user),
        accessor: :temporally_assigned_user_full_name
      },

      {
        label:    human_attribute_name(:status),
        accessor: :current_state_name
      },

      {
        label:    Organisation.model_name.human,
        accessor: :organisation_name
      },

      {
        label:    Team.model_name.human,
        accessor: :team_name
      },

      {
        label:    Project.human_attribute_name(:name),
        accessor: :name
      },

      {
        label:    Project.human_attribute_name(:description),
        accessor: :description
      },

      {
        label:    Project.human_attribute_name(:level_of_identifiability),
        accessor: :level_of_identifiability
      },

      {
        label:    human_attribute_name(:data_end_use),
        accessor: ->(project) { project.end_use_names.join(', ') }
      },

      {
        label:    human_attribute_name(:data_asset_required),
        accessor: ->(project) { project.dataset_names.join(', ') }
      }
    ]

    self.download_only = true

    def relation
      Project.odr_projects.distinct.
        from(subquery, :projects).
        joins(current_project_state: :state).
        where.not(workflow_current_project_states: { state_id: EXCLUDED_STATES }).
        order(:application_manager, :application_log, :amendment_reference).
        preload(
          :current_state,
          :project_type,
          :end_uses,
          :datasets,
          team: :organisation
        )
    end

    private

    # Ensure we get the requested cartesian product and expose attributes/columns from
    # related models/tables as attributes on the returning relation/objects.
    # NOTE: yuk.
    def subquery
      Project.left_joins(:assigned_user, :project_amendments, :releases).
        select(
          'projects.*',
          "NULLIF(CONCAT_WS(' ', users.first_name, users.last_name), '') AS application_manager",
          'project_amendments.reference AS amendment_reference',
          'project_amendments.requested_at AS amendment_date',
          'project_amendments.amendment_approved_date',
          'releases.release_date AS data_release_date',
          'releases.individual_to_release'
        )
    end
  end
end
