# Sends emails regarding CAS related activity
class CasMailer < ApplicationMailer
  before_action :load_project
  before_action :load_project_dataset, only: [:dataset_approved_status_updated,
                                              :dataset_approved_status_updated_to_user]

  def dataset_approved_status_updated
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten.pluck(:email)

    mail(to: recipients, subject: 'Dataset Approval Status Change') if recipients.any?
  end

  def dataset_approved_status_updated_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'Dataset Approval Updated') if recipient.any?
  end

  def access_approval_status_updated
    recipients = SystemRole.cas_manager_and_access_approvers.map(&:users).flatten.pluck(:email)

    mail(to: recipients, subject: 'Access Approval Status Updated') if recipients.any?
  end

  def account_approved_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Approved') if recipient.any?
  end

  def account_access_granted_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Granted') if recipient.any?
  end

  private

  def load_project
    @project ||= params[:project]
  end

  def load_project_dataset
    @project_dataset ||= params[:project_dataset]
  end
end
