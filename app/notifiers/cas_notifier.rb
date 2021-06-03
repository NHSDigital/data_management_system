# Generates `Notification`s relating to Cas projects.
# TODO: text here and in other notifications as a whole should move to translation file
class CasNotifier
  class << self
    def requires_dataset_approval(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Requires Dataset Approval',
        body: "#{project.project_type_name} application #{project.id} - " \
              "Dataset approval is required.\n\n"
      )
    end

    def dataset_level_approved_status_updated(project, project_dataset_level, user_id)
      create_notification(
        user_id: user_id,
        title: 'Dataset Approval Level Status Change',
        body: "#{project.project_type_name} application #{project.id} - Dataset " \
              "'#{project_dataset_level.project_dataset.dataset_name}' has been updated to " \
              "Approval status of '#{project_dataset_level.readable_approved_status}' for level " \
              "#{project_dataset_level.access_level_id}.\n\n"
      )
    end

    def application_submitted(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Submitted',
        body: "#{project.project_type_name} project #{project.id} has been submitted." \
              "\n\n"
      )
    end

    def dataset_level_approved_status_updated_to_user(project, project_dataset_level)
      create_notification(
        user_id: project.owner.id,
        title: 'Dataset Approval Level Updated',
        body: 'Your CAS dataset access request for ' \
              "'#{project_dataset_level.project_dataset.dataset_name}' has been updated to " \
              "Approval status of '#{project_dataset_level.readable_approved_status}' for level " \
              "#{project_dataset_level.access_level_id}.\n\n"
      )
    end

    def requires_account_approval(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Application Requires Access Approval',
        body: "#{project.project_type_name} application #{project.id} - Access approval is required." \
              "\n\n"
      )
    end

    def access_approval_status_updated(project, user_id, state_id)
      create_notification(
        user_id: user_id,
        title: 'Access Approval Status Updated',
        body: "#{project.project_type_name} application #{project.id} - Access approval status has " \
              "been updated to '#{state_id.titlecase}'.\n\n"
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
        body: "#{project.project_type_name} application #{project.id} - Access has been granted by " \
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

    def requires_renewal_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Access Requires Renewal',
        body: 'Your access to CAS needs to be renewed, please visit your application to confirm ' \
              'renewal. If you have not renewed within 30 days your access will be removed and ' \
              "you will need to contact Beatrice Coker to reapply\n\n"
      )
    end

    def requires_renewal_midpoint_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Access Urgently Requires Renewal',
        body: 'Your access to CAS needs to be renewed, please visit your application to confirm ' \
              'renewal. If you have not renewed within 15 days your access will be removed and ' \
              "you will need to contact Beatrice Coker to reapply\n\n"
      )
    end

    def account_closed_to_user(project)
      create_notification(
        user_id: project.owner,
        title: 'CAS Account Closed',
        body: 'Your CAS account has been closed. If you still require access please re-apply ' \
              "using your existing application by clicking the 'return to draft' button.\n\n"
      )
    end

    def account_closed(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Account Has Closed',
        body: "CAS account #{project.id} has been closed.\n\n"
      )
    end

    def account_renewed(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Account Renewed',
        body: "CAS Account #{project.id} has been renewed.\n\n"
      )
    end

    def account_renewed_dataset_approver(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'CAS Account Renewed With Access to Dataset',
        body: "CAS account #{project.id} has been renewed. This account has access to one or " \
              "more datasets that you are an approver for.\n\n"
      )
    end

    def new_cas_project_saved(project, user_id)
      create_notification(
        user_id: user_id,
        title: 'New CAS Application Created',
        body: "#{project.project_type_name} application #{project.id} has been created.\n\n"
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
