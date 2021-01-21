# Sends emails regarding CAS related activity
class CasMailer < ApplicationMailer
  before_action :load_project
  before_action :load_project_dataset, only: [:dataset_approved_status_updated,
                                              :dataset_approved_status_updated_to_user]

  def requires_dataset_approval
    recipient = Array.wrap(params[:user].email)

    mail(to: recipient, subject: 'CAS Application Requires Dataset Approval') if recipient.any?
  end

  def dataset_approved_status_updated
    recipients = User.cas_manager_and_access_approvers.pluck(:email)

    mail(to: recipients, subject: 'Dataset Approval Status Change') if recipients.any?
  end

  def dataset_approved_status_updated_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'Dataset Approval Updated') if recipient.any?
  end

  def application_submitted
    recipients = User.cas_managers.pluck(:email)

    mail(to: recipients, subject: 'CAS Application Submitted') if recipients.any?
  end

  def requires_account_approval
    recipients = User.cas_access_approvers.pluck(:email)

    mail(to: recipients, subject: 'CAS Application Requires Access Approval') if recipients.any?
  end

  def access_approval_status_updated
    recipients = User.cas_manager_and_access_approvers.pluck(:email)

    mail(to: recipients, subject: 'Access Approval Status Updated') if recipients.any?
  end

  def account_approved_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Approved') if recipient.any?
  end

  def account_rejected_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Rejected') if recipient.any?
  end

  def account_access_granted
    recipients = User.cas_managers.pluck(:email)

    mail(to: recipients, subject: 'CAS Access Status Updated') if recipients.any?
  end

  def account_access_granted_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Granted') if recipient.any?
  end

  def requires_renewal_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Access Requires Renewal') if recipient.any?
  end

  def account_closed_to_user
    recipient = Array.wrap(@project.owner.email)

    mail(to: recipient, subject: 'CAS Account Closed') if recipient.any?
  end

  def new_cas_project_saved
    recipients = User.cas_managers.pluck(:email)

    mail(to: recipients, subject: 'New CAS Application Created') if recipients.any?
  end

  private

  def load_project
    @project ||= params[:project]
  end

  def load_project_dataset
    @project_dataset ||= params[:project_dataset]
  end
end
