namespace :workflow do
  task migrate: :environment do
    mappings = {
      'New'               => 'DRAFT',
      'Delegate Approval' => 'REVIEW',
      'Pending'           => 'SUBMITTED',
      'Approved'          => 'APPROVED',
      'Rejected'          => 'REJECTED',
      'Deleted'           => 'DELETED',
      'Expired'           => 'EXPIRED'
    }

    scope = Project.left_joins(:current_state).
            where(workflow_current_project_states: { id: nil }).
            where.not(z_project_status_id: nil)

    total   = scope.count
    updated = 0
    message = ''

    Project.transaction do
      scope.find_each do |project|
        status = ZProjectStatus.find(project.z_project_status_id)
        state  = mappings[status.name]

        next unless state

        if project.project_states.create(state: Workflow::State.find(state))
          updated += 1
        else
          updated = 0
          raise ActiveRecord::Rollback
        end

        print "\b" * message.length
        print message = "Updated #{updated} of #{total} projects"
      end
    end

    puts "\nWorkflow migration #{total.positive? && updated.zero? ? 'failed!' : 'complete'}"
  end
end
