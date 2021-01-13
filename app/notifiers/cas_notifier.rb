# Generates `Notification`s relating to Cas projects.
class CasNotifier
  class << self
    def requires_dataset_approval(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Requires Dataset Approval',
        body: "#{project.project_type.name} project #{project.id} - Dataset approval is required." \
              "\n\n"
      )
    end

    def dataset_approved_status_updated(project, project_dataset, user_id)
      create_notification(
        user_id: user_id,
        title: 'Dataset Approval Status Change',
        body: "#{project.project_type.name} project #{project.id} - Dataset " \
              "'#{project_dataset.dataset_name}' has been updated to Approval status of " \
              "'#{project_dataset.readable_approved_status}'.\n\n"
      )
    end

    def application_submitted(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Submitted',
        body: "#{project.project_type.name} project #{project.id} has been submitted." \
              "\n\n"
      )
    end

    def dataset_approved_status_updated_to_user(project, project_dataset)
      create_notification(
        user_id: project.owner.id,
        title: 'Dataset Approval Updated',
        body: "Your CAS dataset access request for '#{project_dataset.dataset_name}' has been " \
              "updated to Approval status of '#{project_dataset.readable_approved_status}'.\n\n"
      )
    end

    def requires_account_approval(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Requires Access Approval',
        body: "#{project.project_type.name} project #{project.id} - Access approval is required." \
              "\n\n"
      )
    end

    def access_approval_status_updated(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'Access Approval Status Updated',
        body: "#{project.project_type.name} project #{project.id} - Access approval status has " \
              "been updated to '#{project.project_states.last.state_id.titlecase}'.\n\n"
      )
    end

    def account_approved_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Access Approved',
        body: "Your CAS access has been approved for application #{project.id}. You will receive " \
              "a further notification once your account has been updated.\n\n"
      )
    end

    def account_rejected_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Access Rejected',
        body: "Your CAS access has been rejected for application #{project.id}.\n\n"
      )
    end

    def account_access_granted(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Access Status Updated',
        body: "#{project.project_type.name} project #{project.id} - Access has been granted by " \
        "the helpdesk and the applicant now has CAS access.\n\n"
      )
    end

    def account_access_granted_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Access Granted',
        body: 'CAS access has been granted for your account based on application ' \
              "#{project.id}.\n\n"
      )
    end

    private

    def create_notification(**attributes)
      Notification.create(attributes) do |notification|
        notification.generate_mail = false
        yield(notification) if block_given?
      end
    end
  end
end
